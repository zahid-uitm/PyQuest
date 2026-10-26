# res://scripts/ui/GameplayUI.gd
extends Control

# Top Bar Nodes
@onready var pause_button: Button = $LayoutVBox/TopBar/TopBarContainer/PauseButton
@onready var level_title_label: Label = $LayoutVBox/TopBar/TopBarContainer/LevelTitleLabel
@onready var question_tracker_label: Label = $LayoutVBox/TopBar/TopBarContainer/QuestionTrackerLabel
@onready var score_streak_label: Label = $LayoutVBox/TopBar/TopBarContainer/ScoreStreakLabel
@onready var xp_label: Label = $LayoutVBox/TopBar/TopBarContainer/XPLabel
@onready var hint_button: Button = $LayoutVBox/TopBar/TopBarContainer/HintButton
@onready var timer_label: Label = $LayoutVBox/TopBar/TopBarContainer/TimerLabel

# Visual Stage
@onready var visual_stage: Node2D = $LayoutVBox/SplitArea/VisualStageContainer/SubViewport/VisualStage

# Code & Puzzle Panel Nodes
@onready var question_title_label: Label = $LayoutVBox/SplitArea/CodePanel/ScrollContainer/CardVBox/HeaderBar/QuestionTitleLabel
@onready var topic_badge: Label = $LayoutVBox/SplitArea/CodePanel/ScrollContainer/CardVBox/HeaderBar/TopicBadge
@onready var question_prompt_label: Label = $LayoutVBox/SplitArea/CodePanel/ScrollContainer/CardVBox/QuestionPromptLabel
@onready var code_label: RichTextLabel = $LayoutVBox/SplitArea/CodePanel/ScrollContainer/CardVBox/CodeDisplayContainer/CodeVBox/CodeLabel
@onready var answer_area: VBoxContainer = $LayoutVBox/SplitArea/CodePanel/ScrollContainer/CardVBox/AnswerInteractiveArea
@onready var ask_wizard_button: Button = $LayoutVBox/SplitArea/CodePanel/ScrollContainer/CardVBox/ActionRow/AskWizardButton
@onready var submit_button: Button = $LayoutVBox/SplitArea/CodePanel/ScrollContainer/CardVBox/ActionRow/SubmitButton

# Bottom Bar Nodes
@onready var weapon_status_label: Label = $LayoutVBox/BottomBar/BottomBarContainer/WeaponStatusLabel
@onready var progress_text: Label = $LayoutVBox/BottomBar/BottomBarContainer/ProgressText
@onready var level_progress_bar: ProgressBar = $LayoutVBox/BottomBar/BottomBarContainer/LevelProgressBar

# Modals & Overlays
@onready var feedback_overlay: ColorRect = $FeedbackOverlay
@onready var status_title: Label = $FeedbackOverlay/Center/FeedbackCard/FeedbackVBox/StatusTitle
@onready var status_message: Label = $FeedbackOverlay/Center/FeedbackCard/FeedbackVBox/StatusMessage
@onready var explanation_label: Label = $FeedbackOverlay/Center/FeedbackCard/FeedbackVBox/ExplanationBox/ExplanationLabel
@onready var next_button: Button = $FeedbackOverlay/Center/FeedbackCard/FeedbackVBox/NextButton

@onready var hint_modal_overlay: ColorRect = $HintModalOverlay
@onready var hint_message: Label = $HintModalOverlay/Center/HintCard/HintVBox/HintMessage
@onready var close_hint_button: Button = $HintModalOverlay/Center/HintCard/HintVBox/CloseHintButton

@onready var pause_overlay: ColorRect = $PauseMenuOverlay
@onready var resume_button: Button = $PauseMenuOverlay/Center/PauseCard/PauseVBox/ResumeButton
@onready var restart_button: Button = $PauseMenuOverlay/Center/PauseCard/PauseVBox/RestartButton
@onready var quit_button: Button = $PauseMenuOverlay/Center/PauseCard/PauseVBox/QuitButton

@onready var victory_overlay: ColorRect = $VictoryOverlay
@onready var victory_title: Label = $VictoryOverlay/Center/VictoryCard/VictoryVBox/VictoryTitle
@onready var rank_label: Label = $VictoryOverlay/Center/VictoryCard/VictoryVBox/RankLabel
@onready var acc_value: Label = $VictoryOverlay/Center/VictoryCard/VictoryVBox/StatsGrid/AccValue
@onready var streak_value: Label = $VictoryOverlay/Center/VictoryCard/VictoryVBox/StatsGrid/StreakValue
@onready var time_value: Label = $VictoryOverlay/Center/VictoryCard/VictoryVBox/StatsGrid/TimeValue
@onready var score_value: Label = $VictoryOverlay/Center/VictoryCard/VictoryVBox/StatsGrid/ScoreValue
@onready var xp_value: Label = $VictoryOverlay/Center/VictoryCard/VictoryVBox/StatsGrid/XPValue
@onready var replay_button: Button = $VictoryOverlay/Center/VictoryCard/VictoryVBox/VictoryButtonsHBox/ReplayButton
@onready var level_select_btn: Button = $VictoryOverlay/Center/VictoryCard/VictoryVBox/VictoryButtonsHBox/LevelSelectBtn

# Gameplay State
var level_data: Dictionary = {}
var current_question_index: int = 0
var score: int = 0
var total_xp: int = 0
var streak: int = 0
var max_streak: int = 0
var first_try_correct: int = 0
var current_question_attempts: int = 0
var elapsed_time: float = 0.0
var is_timer_active: bool = false

# Interactive State
var current_selected_answer: Variant = null
var current_selected_btn: Button = null
var selected_ordering: Array[int] = []
var mcq_option_buttons: Array[Button] = []
var is_evaluating: bool = false
var last_answer_correct: bool = false

func _ready() -> void:
	feedback_overlay.visible = false
	hint_modal_overlay.visible = false
	pause_overlay.visible = false
	victory_overlay.visible = false

	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	next_button.pressed.connect(_on_next_question_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	ask_wizard_button.pressed.connect(_on_hint_pressed)
	close_hint_button.pressed.connect(_on_close_hint_pressed)

	submit_button.pressed.connect(_on_submit_pressed)
	replay_button.pressed.connect(_on_restart_pressed)
	level_select_btn.pressed.connect(_on_quit_pressed)

	var cur_lvl = SaveManager.user_profile.get("current_level", 1)
	var path = "res://data/" + "question_level%d.json" % cur_lvl
	if not FileAccess.file_exists(path):
		path = "res://data/question_level1.json"
	load_level_json(path)

func _process(delta: float) -> void:
	if is_timer_active:
		elapsed_time += delta
		var minutes: int = int(elapsed_time) / 60
		var seconds: int = int(elapsed_time) % 60
		timer_label.text = "⏱ %02d:%02d" % [minutes, seconds]

func load_level_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Question JSON not found: %s" % path)
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var json_str = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_str)
	if typeof(parsed) == TYPE_DICTIONARY:
		level_data = parsed
		start_level()
	else:
		push_error("Failed to parse level JSON: %s" % path)

func start_level() -> void:
	current_question_index = 0
	score = 0
	total_xp = 0
	streak = 0
	max_streak = 0
	first_try_correct = 0
	current_question_attempts = 0
	elapsed_time = 0.0
	is_timer_active = true
	is_evaluating = false
	
	feedback_overlay.visible = false
	hint_modal_overlay.visible = false
	pause_overlay.visible = false
	victory_overlay.visible = false

	if visual_stage and visual_stage.has_method("reset_stage"):
		visual_stage.reset_stage()

	update_hud()
	display_question()

func update_hud() -> void:
	var total_q = level_data.get("questions", []).size()
	level_title_label.text = "⚔️ " + level_data.get("level_title", "Level 1: Variable Valley")
	question_tracker_label.text = "Challenge %d / %d" % [current_question_index + 1, total_q]

	var mult: float = min(2.0, 1.0 + (streak * 0.1))
	score_streak_label.text = "⭐ Score: %d | 🔥 x%.1f" % [score, mult]
	xp_label.text = "✨ XP: %d" % total_xp

	var tokens: int = int(SaveManager.user_profile.get("hint_tokens", 5))
	hint_button.text = "💡 Tokens: %d" % tokens
	ask_wizard_button.text = "🧙 Ask Master PyWizard (%d left)" % tokens

	progress_text.text = "Progress: %d/%d" % [current_question_index + 1, total_q]
	level_progress_bar.max_value = total_q
	level_progress_bar.value = current_question_index + 1

func display_question() -> void:
	current_selected_answer = null
	current_selected_btn = null
	selected_ordering.clear()
	mcq_option_buttons.clear()
	current_question_attempts = 0

	for child in answer_area.get_children():
		child.queue_free()

	var questions: Array = level_data.get("questions", [])
	if current_question_index >= questions.size():
		finish_level()
		return

	var q: Dictionary = questions[current_question_index]
	question_title_label.text = q.get("title", "Python Challenge")
	topic_badge.text = level_data.get("topic", "Variables & Data Types")
	question_prompt_label.text = q.get("prompt", "")

	var raw_snippet: String = q.get("code_snippet", "")
	code_label.text = "[code]%s[/code]" % raw_snippet

	update_hud()

	var q_type: String = q.get("type", "multiple_choice")
	if q_type == "multiple_choice":
		_setup_multiple_choice(q)
	elif q_type == "code_completion":
		_setup_code_completion(q)
	elif q_type == "syntax_ordering":
		_setup_syntax_ordering(q)

func _setup_multiple_choice(q: Dictionary) -> void:
	var options: Array = q.get("options", [])
	var instruction = Label.new()
	instruction.text = "Select the correct code statement:"
	instruction.add_theme_color_override("font_color", Color("#94A3B8"))
	answer_area.add_child(instruction)

	for i in range(options.size()):
		var btn = Button.new()
		btn.text = options[i]
		btn.custom_minimum_size = Vector2(0, 48)
		btn.focus_mode = Control.FOCUS_NONE
		_apply_option_style(btn, false)
		btn.pressed.connect(_on_mcq_option_selected.bind(i, btn))
		answer_area.add_child(btn)
		mcq_option_buttons.append(btn)

	submit_button.text = "▶ Submit Answer"
	submit_button.disabled = true

func _on_mcq_option_selected(index: int, btn: Button) -> void:
	current_selected_answer = index
	for b in mcq_option_buttons:
		_apply_option_style(b, false)
	_apply_option_style(btn, true)
	submit_button.disabled = false

func _setup_code_completion(q: Dictionary) -> void:
	var options: Array = q.get("options", [])
	var instruction = Label.new()
	instruction.text = "Choose the token to fill into '____':"
	instruction.add_theme_color_override("font_color", Color("#94A3B8"))
	answer_area.add_child(instruction)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)

	for opt in options:
		var btn = Button.new()
		btn.text = opt
		btn.custom_minimum_size = Vector2(120, 50)
		btn.focus_mode = Control.FOCUS_NONE
		_apply_option_style(btn, false)
		btn.pressed.connect(_on_completion_option_selected.bind(opt, btn, q))
		hbox.add_child(btn)
		mcq_option_buttons.append(btn)

	answer_area.add_child(hbox)
	submit_button.text = "▶ Submit & Run Code"
	submit_button.disabled = true

func _on_completion_option_selected(token: String, btn: Button, q: Dictionary) -> void:
	current_selected_answer = token
	for b in mcq_option_buttons:
		_apply_option_style(b, false)
	_apply_option_style(btn, true)

	var snippet: String = q.get("code_snippet", "")
	var filled_snippet = snippet.replace("____", "[color=#F59E0B]%s[/color]" % token)
	code_label.text = "[code]%s[/code]" % filled_snippet
	submit_button.disabled = false

func _setup_syntax_ordering(q: Dictionary) -> void:
	selected_ordering.clear()
	var blocks: Array = q.get("blocks", [])

	var instruction = Label.new()
	instruction.text = "Click blocks in the correct logical execution order:"
	instruction.add_theme_color_override("font_color", Color("#94A3B8"))
	answer_area.add_child(instruction)

	var blocks_vbox = VBoxContainer.new()
	blocks_vbox.add_theme_constant_override("separation", 10)

	for i in range(blocks.size()):
		var btn = Button.new()
		btn.text = blocks[i]
		btn.custom_minimum_size = Vector2(0, 44)
		btn.focus_mode = Control.FOCUS_NONE
		_apply_option_style(btn, false)
		btn.pressed.connect(_on_order_block_clicked.bind(i, btn, q))
		blocks_vbox.add_child(btn)
		mcq_option_buttons.append(btn)

	answer_area.add_child(blocks_vbox)

	var reset_btn = Button.new()
	reset_btn.text = "↺ Reset Block Order"
	reset_btn.custom_minimum_size = Vector2(0, 36)
	reset_btn.focus_mode = Control.FOCUS_NONE
	reset_btn.pressed.connect(func():
		selected_ordering.clear()
		for b in mcq_option_buttons:
			b.disabled = false
			_apply_option_style(b, false)
		code_label.text = "[code]# Select blocks below to construct sequence[/code]"
		submit_button.disabled = true
	)
	answer_area.add_child(reset_btn)

	code_label.text = "[code]# Select blocks below to construct sequence[/code]"
	submit_button.text = "▶ Execute Ordered Script"
	submit_button.disabled = true

func _on_order_block_clicked(block_idx: int, btn: Button, q: Dictionary) -> void:
	if selected_ordering.has(block_idx):
		return
	selected_ordering.append(block_idx)
	btn.disabled = true

	var blocks: Array = q.get("blocks", [])
	var code_assembled = ""
	for idx in selected_ordering:
		code_assembled += blocks[idx] + "\n"
	code_label.text = "[code]%s[/code]" % code_assembled.strip_edges()

	if selected_ordering.size() == blocks.size():
		submit_button.disabled = false

func _on_submit_pressed() -> void:
	if is_evaluating:
		return
	is_evaluating = true
	submit_button.disabled = true
	current_question_attempts += 1

	var q: Dictionary = level_data.get("questions", [])[current_question_index]
	var q_type: String = q.get("type", "multiple_choice")
	var is_correct: bool = false

	if q_type == "multiple_choice":
		var correct_idx = int(q.get("correct_index", 0))
		is_correct = (current_selected_answer == correct_idx)
	elif q_type == "code_completion":
		var correct_str = str(q.get("correct_answer", ""))
		is_correct = (str(current_selected_answer) == correct_str)
	elif q_type == "syntax_ordering":
		var correct_seq: Array = q.get("correct_sequence", [])
		is_correct = true
		if selected_ordering.size() != correct_seq.size():
			is_correct = false
		else:
			for k in range(selected_ordering.size()):
				if selected_ordering[k] != int(correct_seq[k]):
					is_correct = false
					break

	last_answer_correct = is_correct

	# Formula calculations
	if is_correct:
		if current_question_attempts == 1:
			first_try_correct += 1
		streak += 1
		max_streak = max(max_streak, streak)
		var mult: float = min(2.0, 1.0 + (streak * 0.1))
		var earned_pts: int = roundi(100.0 * mult)
		var earned_xp: int = roundi(50.0 * mult)
		score += earned_pts
		total_xp += earned_xp
		update_hud()

		# Trigger visual action on stage
		if visual_stage and visual_stage.has_method("play_correct_action"):
			await visual_stage.play_correct_action(q.get("action_trigger", "unlock"), earned_pts, earned_xp)

		_show_feedback(true, q, earned_pts, earned_xp, mult)
	else:
		streak = 0
		update_hud()
		if visual_stage and visual_stage.has_method("play_incorrect_action"):
			await visual_stage.play_incorrect_action()

		_show_feedback(false, q, 0, 0, 1.0)

	is_evaluating = false

func _show_feedback(is_correct: bool, q: Dictionary, earned_pts: int, earned_xp: int, mult: float) -> void:
	feedback_overlay.visible = true
	if is_correct:
		status_title.text = "🎉 CODE EXECUTED SUCCESSFULLY!"
		status_title.add_theme_color_override("font_color", Color("#10B981"))
		status_message.text = "+%d Score  •  +%d XP  •  Streak Multiplier: x%.1f 🔥" % [earned_pts, earned_xp, mult]
		explanation_label.text = q.get("explanation", "Excellent work! Python variable syntax correct.")
		next_button.text = "Continue Adventure ➔"
	else:
		status_title.text = "⚠️ EXECUTION FAILED: SYNTAX ERROR"
		status_title.add_theme_color_override("font_color", Color("#EF4444"))
		status_message.text = "The mechanism did not budge. Streak reset to 0."
		explanation_label.text = q.get("explanation", "Review the required Python syntax rules.")
		next_button.text = "Try Again ↺" if current_question_attempts < 3 else "Continue ➔"

func _on_next_question_pressed() -> void:
	feedback_overlay.visible = false
	if last_answer_correct or current_question_attempts >= 3:
		current_question_index += 1
	display_question()

func _on_hint_pressed() -> void:
	var tokens: int = int(SaveManager.user_profile.get("hint_tokens", 5))
	var q: Dictionary = level_data.get("questions", [])[current_question_index]

	if tokens > 0:
		tokens -= 1
		SaveManager.user_profile["hint_tokens"] = tokens
		SaveManager.save_local_profile()
		update_hud()

		if visual_stage and visual_stage.has_method("show_pywizard_hint"):
			visual_stage.show_pywizard_hint()

		# Eliminate one wrong option for MCQ if possible
		if q.get("type") == "multiple_choice" and mcq_option_buttons.size() > 1:
			var correct_idx: int = int(q.get("correct_index", 0))
			for i in range(mcq_option_buttons.size()):
				if i != correct_idx and not mcq_option_buttons[i].disabled:
					mcq_option_buttons[i].disabled = true
					mcq_option_buttons[i].text = "❌ " + mcq_option_buttons[i].text
					break

		hint_message.text = q.get("hint", "Master PyWizard says: Check your variable assignment syntax.")
	else:
		hint_message.text = "You have exhausted your hint tokens for this expedition! Trust your Python instincts."

	hint_modal_overlay.visible = true

func _on_close_hint_pressed() -> void:
	hint_modal_overlay.visible = false

func finish_level() -> void:
	is_timer_active = false
	var total_q = max(1, level_data.get("questions", []).size())
	var accuracy: float = (float(first_try_correct) / float(total_q)) * 100.0

	# GDD Star Rating:
	# 3 Stars >= 90%
	# 2 Stars >= 70%
	# 1 Star < 70%
	var stars: int = 1
	var title_rank: String = "Survivor (★☆☆)"
	if accuracy >= 90.0:
		stars = 3
		title_rank = "Master Adventurer (★★★)"
	elif accuracy >= 70.0:
		stars = 2
		title_rank = "Experienced Explorer (★★☆)"

	# Time Bonus formula from GDD: max(0, 300 - elapsed) * 2
	var time_bonus: int = max(0, int((300.0 - elapsed_time) * 2.0))
	var final_score: int = score + time_bonus

	# Update stats in SaveManager
	var level_num: int = int(level_data.get("level_id", 1))
	SaveManager.record_level_completion(level_num, final_score, total_xp, stars)

	# Populate Victory Overlay
	acc_value.text = "%.1f%%" % accuracy
	var mult: float = min(2.0, 1.0 + (max_streak * 0.1))
	streak_value.text = "%d (x%.1f Max)" % [max_streak, mult]
	time_value.text = "+%d pts (%02d:%02d)" % [time_bonus, int(elapsed_time)/60, int(elapsed_time)%60]
	score_value.text = "%d pts" % final_score
	xp_value.text = "+%d XP" % total_xp
	rank_label.text = title_rank

	victory_overlay.visible = true

func _apply_option_style(btn: Button, is_selected: bool) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.set_border_width_all(2)

	if is_selected:
		style.bg_color = Color("#1E293B")
		style.border_color = Color("#F59E0B")
		btn.add_theme_color_override("font_color", Color("#F59E0B"))
	else:
		style.bg_color = Color("#111827")
		style.border_color = Color("#1F2937")
		btn.add_theme_color_override("font_color", Color("#E2E8F0"))

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func _on_pause_pressed() -> void:
	is_timer_active = false
	pause_overlay.visible = true

func _on_resume_pressed() -> void:
	pause_overlay.visible = false
	is_timer_active = true

func _on_restart_pressed() -> void:
	start_level()

func _on_quit_pressed() -> void:
	SceneManager.change_scene(SceneManager.WORLD_1)
