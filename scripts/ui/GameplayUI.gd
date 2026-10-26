# res://scripts/ui/GameplayUI.gd
extends Control

# Top Bar Nodes
@onready var question_tracker_label: Label = $TopBar/TopBarContainer/QuestionTrackerLabel
@onready var timer_label: Label = $TopBar/TopBarContainer/TimerLabel
@onready var score_streak_label: Label = $TopBar/TopBarContainer/ScoreStreakLabel
@onready var hint_button: Button = $TopBar/TopBarContainer/HintButton
@onready var pause_button: Button = $TopBar/TopBarContainer/PauseButton

# Main Question Nodes
@onready var question_prompt_label: Label = $MainContainer/QuestionCard/CardVBox/QuestionPromptLabel
@onready var code_display_container: PanelContainer = $MainContainer/QuestionCard/CardVBox/CodeDisplayContainer
@onready var code_label: RichTextLabel = $MainContainer/QuestionCard/CardVBox/CodeDisplayContainer/CodeLabel
@onready var answer_area: VBoxContainer = $MainContainer/QuestionCard/CardVBox/AnswerInteractiveArea

# Feedback Overlay Nodes
@onready var feedback_overlay: ColorRect = $FeedbackOverlay
@onready var status_title: Label = $FeedbackOverlay/FeedbackCard/FeedbackVBox/StatusTitle
@onready var status_message: Label = $FeedbackOverlay/FeedbackCard/FeedbackVBox/StatusMessage
@onready var next_button: Button = $FeedbackOverlay/FeedbackCard/FeedbackVBox/NextButton

# Pause Menu Nodes
@onready var pause_overlay: ColorRect = $PauseMenuOverlay
@onready var resume_button: Button = $PauseMenuOverlay/PauseCard/PauseVBox/ResumeButton
@onready var restart_button: Button = $PauseMenuOverlay/PauseCard/PauseVBox/RestartButton
@onready var quit_button: Button = $PauseMenuOverlay/PauseCard/PauseVBox/QuitButton

# State Variables
var level_data: Dictionary = {}
var current_question_index: int = 0
var score: int = 0
var streak: int = 0
var correct_answers_count: int = 0
var elapsed_time: float = 0.0
var is_timer_active: bool = false

# Current Selected State for Ordering / Blank Filling
var selected_ordering: Array[int] = []

func _ready() -> void:
	feedback_overlay.visible = false
	pause_overlay.visible = false
	
	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	next_button.pressed.connect(_on_next_question_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	
	load_level_json("res://data/question_level1.json")

func _process(delta: float) -> void:
	if is_timer_active:
		elapsed_time += delta
		var minutes: int = int(elapsed_time) / 60
		var seconds: int = int(elapsed_time) % 60
		timer_label.text = "⏱ %02d:%02d" % [minutes, seconds]

func load_level_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		print("Error: Question JSON file not found at ", path)
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) == OK:
		level_data = json.data
		start_level()
	else:
		print("Error parsing JSON level file.")

func start_level() -> void:
	current_question_index = 0
	score = 0
	streak = 0
	correct_answers_count = 0
	elapsed_time = 0.0
	is_timer_active = true
	update_hud()
	display_question()

func update_hud() -> void:
	var total_q = level_data.get("questions", []).size()
	question_tracker_label.text = "Question %d / %d" % [current_question_index + 1, total_q]
	score_streak_label.text = "Score: %d | 🔥 %d" % [score, streak]
	var tokens = SaveManager.user_profile.get("hint_tokens", 5)
	hint_button.text = "💡 Hint (%d)" % tokens

func display_question() -> void:
	# Clear interactive area
	for child in answer_area.get_children():
		child.queue_free()

	var questions: Array = level_data.get("questions", [])
	if current_question_index >= questions.size():
		finish_level()
		return

	var q: Dictionary = questions[current_question_index]
	question_prompt_label.text = q.get("prompt", "")
	update_hud()

	var q_type: String = q.get("type", "")
	
	if q_type == "multiple_choice":
		code_display_container.visible = false
		_setup_multiple_choice(q)
	elif q_type == "code_completion":
		code_display_container.visible = true
		code_label.text = "[code]%s[/code]" % q.get("code_snippet", "")
		_setup_code_completion(q)
	elif q_type == "syntax_ordering":
		code_display_container.visible = false
		_setup_syntax_ordering(q)

func _setup_multiple_choice(q: Dictionary) -> void:
	var options: Array = q.get("options", [])
	for i in range(options.size()):
		var btn = Button.new()
		btn.text = options[i]
		btn.custom_minimum_size = Vector2(0, 50)
		_apply_button_style(btn)
		btn.pressed.connect(_evaluate_answer.bind(i == q.get("correct_index", -1)))
		answer_area.add_child(btn)

func _setup_code_completion(q: Dictionary) -> void:
	var options: Array = q.get("options", [])
	var correct_ans: String = q.get("correct_answer", "")
	for opt in options:
		var btn = Button.new()
		btn.text = opt
		btn.custom_minimum_size = Vector2(0, 50)
		_apply_button_style(btn)
		btn.pressed.connect(_evaluate_answer.bind(opt == correct_ans))
		answer_area.add_child(btn)

func _setup_syntax_ordering(q: Dictionary) -> void:
	selected_ordering.clear()
	var blocks: Array = q.get("blocks", [])
	
	var display_label = Label.new()
	display_label.name = "OrderResultLabel"
	display_label.text = "Your Order: [ Select blocks below ]"
	display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	answer_area.add_child(display_label)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	
	for i in range(blocks.size()):
		var btn = Button.new()
		btn.text = blocks[i]
		btn.custom_minimum_size = Vector2(80, 50)
		_apply_button_style(btn)
		btn.pressed.connect(_on_block_clicked.bind(i, btn, display_label, q))
		hbox.add_child(btn)
	
	answer_area.add_child(hbox)

func _on_block_clicked(block_idx: int, btn: Button, display_label: Label, q: Dictionary) -> void:
	if selected_ordering.has(block_idx):
		return
		
	selected_ordering.append(block_idx)
	btn.disabled = true
	
	var blocks: Array = q.get("blocks", [])
	var result_text = ""
	for idx in selected_ordering:
		result_text += blocks[idx] + " "
	display_label.text = "Your Order: " + result_text
	
	# Auto check when all blocks are selected
	if selected_ordering.size() == blocks.size():
		var correct_seq: Array = q.get("correct_sequence", [])
		var is_correct: bool = (selected_ordering == correct_seq)
		_evaluate_answer(is_correct)

func _evaluate_answer(is_correct: bool) -> void:
	is_timer_active = false
	feedback_overlay.visible = true
	
	if is_correct:
		streak += 1
		correct_answers_count += 1
		var points: int = 100 + (streak * 20)
		score += points
		status_title.text = "🎉 Correct!"
		status_title.add_theme_color_override("font_color", Color("#10B981"))
		status_message.text = "+%d XP | Streak: %d🔥" % [points, streak]
	else:
		streak = 0
		status_title.text = "❌ Incorrect"
		status_title.add_theme_color_override("font_color", Color("#EF4444"))
		status_message.text = "Streak reset. Keep going!"

func _on_next_question_pressed() -> void:
	feedback_overlay.visible = false
	current_question_index += 1
	is_timer_active = true
	display_question()

func _on_hint_pressed() -> void:
	var tokens = SaveManager.user_profile.get("hint_tokens", 5)
	if tokens > 0:
		tokens -= 1
		SaveManager.user_profile["hint_tokens"] = tokens
		update_hud()
		var q: Dictionary = level_data.get("questions", [])[current_question_index]
		status_title.text = "💡 Hint"
		status_title.add_theme_color_override("font_color", Color("#F59E0B"))
		status_message.text = q.get("hint", "No hint available.")
		feedback_overlay.visible = true

func finish_level() -> void:
	is_timer_active = false
	var total_q = level_data.get("questions", []).size()
	var accuracy: float = (float(correct_answers_count) / float(total_q)) * 100.0
	
	# Pass stats to SaveManager
	SaveManager.user_profile["xp"] = int(SaveManager.user_profile.get("xp", 0)) + score
	if SaveManager.user_profile.get("unlocked_level", 1) <= 1:
		SaveManager.user_profile["unlocked_level"] = 2
		
	SaveManager.save_local_data()
	
	# Route to Level Complete screen or Main Menu
	print("Level 1 Completed! Final Score: %d | Accuracy: %.1f%%" % [score, accuracy])
	SceneManager.change_scene(SceneManager.LEVEL_SELECT)

func _apply_button_style(btn: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#161F33")
	style.border_color = Color("#2E3D5A")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color("#FFFFFF"))

func _on_pause_pressed() -> void:
	is_timer_active = false
	pause_overlay.visible = true

func _on_resume_pressed() -> void:
	pause_overlay.visible = false
	is_timer_active = true

func _on_restart_pressed() -> void:
	pause_overlay.visible = false
	start_level()

func _on_quit_pressed() -> void:
	SceneManager.change_scene(SceneManager.LEVEL_SELECT)
