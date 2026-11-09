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
@onready var hint_message: Label = get_node_or_null("HintModalOverlay/Center/HintCard/HintHBox/HintVBox/HintMessage") as Label
@onready var close_hint_button: Button = get_node_or_null("HintModalOverlay/Center/HintCard/HintHBox/HintVBox/CloseHintButton") as Button

@onready var pause_overlay: ColorRect = $PauseMenuOverlay
@onready var resume_button: Button = $PauseMenuOverlay/Center/PauseCard/PauseVBox/ResumeButton
@onready var restart_button: Button = $PauseMenuOverlay/Center/PauseCard/PauseVBox/RestartButton
@onready var settings_button: Button = get_node_or_null("PauseMenuOverlay/Center/PauseCard/PauseVBox/SettingsButton")
@onready var quit_button: Button = $PauseMenuOverlay/Center/PauseCard/PauseVBox/QuitButton
@onready var settings_modal: Control = get_node_or_null("SettingsModal")

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
var _hints_used_this_battle: int = 0
var bottom_dialog_bar: CanvasLayer = null

# World 6: 5 Generals' Siege Assist State
var generals_assist_bar: PanelContainer = null
var general_assist_buttons: Dictionary = {}
var general_assists_used: Dictionary = {}
var chronos_shield_active: bool = false
var lambda_overcharge_active: bool = false
var assist_status_label: Label = null

func _ready() -> void:
	feedback_overlay.visible = false
	hint_modal_overlay.visible = false
	pause_overlay.visible = false
	victory_overlay.visible = false

	var bdb_scene = load("res://scenes/ui/BottomDialogBar.tscn")
	if bdb_scene:
		bottom_dialog_bar = bdb_scene.instantiate()
		add_child(bottom_dialog_bar)

	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	if settings_button and settings_modal:
		settings_button.pressed.connect(_on_settings_pressed)
		settings_modal.settings_closed.connect(_apply_settings)
	_apply_settings()

	if not hint_message:
		hint_message = find_child("HintMessage", true, false) as Label
	if not close_hint_button:
		close_hint_button = find_child("CloseHintButton", true, false) as Button

	if next_button and not next_button.pressed.is_connected(_on_next_question_pressed):
		next_button.pressed.connect(_on_next_question_pressed)
	if hint_button and not hint_button.pressed.is_connected(_on_hint_pressed):
		hint_button.pressed.connect(_on_hint_pressed)
	if ask_wizard_button and not ask_wizard_button.pressed.is_connected(_on_hint_pressed):
		ask_wizard_button.pressed.connect(_on_hint_pressed)
	if close_hint_button and not close_hint_button.pressed.is_connected(_on_close_hint_pressed):
		close_hint_button.pressed.connect(_on_close_hint_pressed)

	if submit_button and not submit_button.pressed.is_connected(_on_submit_pressed):
		submit_button.pressed.connect(_on_submit_pressed)
	if replay_button and not replay_button.pressed.is_connected(_on_return_current_world_pressed):
		replay_button.pressed.connect(_on_return_current_world_pressed)
	if level_select_btn and not level_select_btn.pressed.is_connected(_on_go_next_world_pressed):
		level_select_btn.pressed.connect(_on_go_next_world_pressed)

	var cur_lvl = int(SaveManager.user_profile.get("current_level", 1))
	AudioManager.play_boss_theme(cur_lvl)
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
	is_timer_active = false
	is_evaluating = false
	
	feedback_overlay.visible = false
	hint_modal_overlay.visible = false
	pause_overlay.visible = false
	victory_overlay.visible = false

	if visual_stage and visual_stage.has_method("reset_stage"):
		visual_stage.reset_stage()

	var cur_lvl = int(level_data.get("level_id", SaveManager.user_profile.get("current_level", 1)))
	AudioManager.play_boss_theme(cur_lvl)

	general_assists_used.clear()
	chronos_shield_active = false
	lambda_overcharge_active = false
	_setup_generals_assist_bar(cur_lvl)

	update_hud()
	display_question()

	if bottom_dialog_bar and bottom_dialog_bar.has_method("play_boss_intro"):
		bottom_dialog_bar.play_boss_intro(cur_lvl)
		await bottom_dialog_bar.dialog_finished
	if is_inside_tree():
		is_timer_active = true

func update_hud() -> void:
	var total_q = level_data.get("questions", []).size()
	level_title_label.text = "⚔️ " + level_data.get("level_title", "Boss Trial: NullByte")
	question_tracker_label.text = "Boss Phase %d / %d" % [current_question_index + 1, total_q]

	var mult: float = min(2.0, 1.0 + (streak * 0.1))
	score_streak_label.text = "⭐ Score: %d | 🔥 x%.1f" % [score, mult]
	xp_label.text = "✨ XP: %d" % total_xp

	var tokens: int = int(SaveManager.user_profile.get("hint_tokens", 5))
	hint_button.text = "💡 Tokens: %d" % tokens
	ask_wizard_button.text = "🧙 Ask Master PyWizard (%d left)" % tokens

	var boss_hp_left = max(0, (total_q - current_question_index) * 100)
	var hero_hp_left = 100
	if visual_stage and "hero_hp" in visual_stage:
		hero_hp_left = max(0, int(visual_stage.hero_hp))
	var cur_lvl = int(level_data.get("level_id", SaveManager.user_profile.get("current_level", 1)))
	var b_name = "Lord SegFault" if cur_lvl == 6 else ("Ignis-Py" if cur_lvl == 5 else ("Vektor-Zero" if cur_lvl == 4 else ("Lambda-Prime" if cur_lvl == 3 else ("Chronos-If" if cur_lvl == 2 else "NullByte"))))
	weapon_status_label.text = "🛡️ Alex HP: %d/100  |  🐉 Boss %s HP: %d/%d  |  🐍 Python 3.12 Grimoire" % [hero_hp_left, b_name, boss_hp_left, total_q * 100]
	progress_text.text = "Boss Phase: %d/%d" % [current_question_index + 1, total_q]
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
	elif q_type == "bug_hunt":
		_setup_bug_hunt(q)

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

	submit_button.text = "⚡ Cast Spell & Strike!"
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
	submit_button.text = "⚡ Cast Spell & Strike!"
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
	submit_button.text = "⚡ Unleash Final Spell Combo!"
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

func _setup_bug_hunt(q: Dictionary) -> void:
	var bug_lines: Array = q.get("bug_lines", [])
	var instruction = Label.new()
	instruction.text = "🐛 LIVE CODE DEBUGGER: Click the corrupted line of Python code to patch the bug:"
	instruction.add_theme_color_override("font_color", Color("#FCA5A5"))
	answer_area.add_child(instruction)

	var lines_vbox = VBoxContainer.new()
	lines_vbox.add_theme_constant_override("separation", 8)

	for i in range(bug_lines.size()):
		var btn = Button.new()
		btn.text = "Line %d:   %s" % [i + 1, str(bug_lines[i])]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 42)
		btn.focus_mode = Control.FOCUS_NONE
		_apply_option_style(btn, false)
		btn.pressed.connect(_on_bug_line_selected.bind(i, btn, q))
		lines_vbox.add_child(btn)
		mcq_option_buttons.append(btn)

	answer_area.add_child(lines_vbox)
	submit_button.text = "🛠️ Patch Bug & Counter-Strike!"
	submit_button.disabled = true

func _on_bug_line_selected(line_idx: int, btn: Button, q: Dictionary) -> void:
	current_selected_answer = line_idx
	for b in mcq_option_buttons:
		_apply_option_style(b, false)
	_apply_option_style(btn, true)

	var bug_lines: Array = q.get("bug_lines", [])
	var correct_idx: int = int(q.get("correct_line", -1))
	var fixed_line: String = str(q.get("fixed_line", ""))
	var preview_lines: Array[String] = []
	for i in range(bug_lines.size()):
		if i == line_idx:
			if i == correct_idx and not fixed_line.is_empty():
				preview_lines.append("[color=#4ADE80]%s  # <-- PATCHED![/color]" % fixed_line)
			else:
				preview_lines.append("[color=#F59E0B]%s  # <-- INSPECTING LINE %d[/color]" % [str(bug_lines[i]), i + 1])
		else:
			preview_lines.append(str(bug_lines[i]))
	code_label.text = "[code]%s[/code]" % "\n".join(preview_lines)
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
	elif q_type == "bug_hunt":
		var correct_line_idx = int(q.get("correct_line", 0))
		is_correct = (int(current_selected_answer) == correct_line_idx)

	last_answer_correct = is_correct

	# Formula calculations
	if is_correct:
		if current_question_attempts == 1:
			first_try_correct += 1
		streak += 1
		max_streak = max(max_streak, streak)
		if streak >= 5:
			BadgeManager.check_all_badges({"code_streak": streak})
		var mult: float = min(2.0, 1.0 + (streak * 0.1))
		var earned_pts: int = roundi(100.0 * mult)
		var earned_xp: int = roundi(50.0 * mult)
		if lambda_overcharge_active:
			lambda_overcharge_active = false
			earned_pts *= 2
			earned_xp += 150
			_refresh_generals_assist_bar()
		score += earned_pts
		total_xp += earned_xp
		update_hud()

		# Trigger visual action on stage
		if visual_stage and visual_stage.has_method("play_correct_action"):
			await visual_stage.play_correct_action(q.get("action_trigger", "unlock"), earned_pts, earned_xp)

		_show_feedback(true, q, earned_pts, earned_xp, mult)
	else:
		var was_shielded: bool = chronos_shield_active
		if chronos_shield_active:
			chronos_shield_active = false
			_refresh_generals_assist_bar()
		else:
			streak = 0
		update_hud()
		AudioManager.play_error()
		if visual_stage and visual_stage.has_method("play_incorrect_action"):
			await visual_stage.play_incorrect_action(was_shielded)

		_show_feedback(false, q, 0, 0, 1.0, was_shielded)

	is_evaluating = false

func _show_feedback(is_correct: bool, q: Dictionary, earned_pts: int, earned_xp: int, mult: float, was_shielded: bool = false) -> void:
	update_hud()
	if is_correct:
		feedback_overlay.visible = true
		status_title.text = "⚔️ DIRECT SPELL HIT! (-100 BOSS HP)"
		status_title.add_theme_color_override("font_color", Color("#10B981"))
		status_message.text = "+%d Score  •  +%d XP  •  Combo Streak: x%.1f 🔥" % [earned_pts, earned_xp, mult]
		explanation_label.text = q.get("explanation", "Excellent work! Python variable syntax correct.")
		next_button.text = "Next Boss Phase ➔"
	else:
		var cur_lvl = int(SaveManager.user_profile.get("current_level", 1))
		var b_name = "Lord SegFault" if cur_lvl == 6 else ("Ignis-Py" if cur_lvl == 5 else ("Vektor-Zero" if cur_lvl == 4 else ("Lambda-Prime" if cur_lvl == 3 else ("Chronos-If" if cur_lvl == 2 else "NullByte"))))
		var hero_dead = visual_stage and visual_stage.has_method("is_hero_dead") and visual_stage.is_hero_dead()
		if hero_dead:
			is_timer_active = false
			if bottom_dialog_bar and bottom_dialog_bar.has_method("play_boss_outro"):
				bottom_dialog_bar.play_boss_outro(cur_lvl, false)
				await bottom_dialog_bar.dialog_finished
			if not is_inside_tree():
				return
			feedback_overlay.visible = true
			status_title.text = "💀 ALEX HAS FALLEN! (0 / 100 HP)"
			status_title.add_theme_color_override("font_color", Color("#EF4444"))
			status_message.text = "%s's Arcane Blade shattered your shield! Study the spell explanation below and challenge the Boss again." % b_name
			explanation_label.text = q.get("explanation", "Review the required Python syntax rules.")
			next_button.text = "↺ Retry Boss Battle"
		else:
			feedback_overlay.visible = true
			var hp_left = int(visual_stage.hero_hp) if (visual_stage and "hero_hp" in visual_stage) else 65
			if was_shielded:
				status_title.text = "🛡️ CHRONOS TEMPORAL SHIELD BLOCKED THE COUNTERATTACK!"
				status_title.add_theme_color_override("font_color", Color("#38BDF8"))
				status_message.text = "General Chronos-If froze %s's counterattack in time! (0 HP Damage • %d/100 HP left • Streak Preserved!)" % [b_name, hp_left]
			else:
				status_title.text = "💥 BOSS COUNTERATTACK: SYNTAX ERROR!"
				status_title.add_theme_color_override("font_color", Color("#EF4444"))
				status_message.text = "%s deflected your spell and struck back! (-35 Shield HP • %d/100 HP left • Streak reset)" % [b_name, hp_left]
			explanation_label.text = q.get("explanation", "Review the required Python syntax rules.")
			next_button.text = "Recast Spell ↺" if current_question_attempts < 3 else "Next Phase ➔"

func _on_next_question_pressed() -> void:
	feedback_overlay.visible = false
	if visual_stage and visual_stage.has_method("is_hero_dead") and visual_stage.is_hero_dead():
		start_level()
		return
	if last_answer_correct or current_question_attempts >= 3:
		current_question_index += 1
	display_question()

func _on_hint_pressed() -> void:
	_hints_used_this_battle += 1
	var tokens: int = int(SaveManager.user_profile.get("hint_tokens", 5))
	var q: Dictionary = level_data.get("questions", [])[current_question_index]

	if tokens > 0:
		tokens -= 1
		SaveManager.user_profile["hint_tokens"] = tokens
		SaveManager.save_local_profile()
		update_hud()

		if visual_stage and visual_stage.has_method("show_pywizard_hint"):
			visual_stage.show_pywizard_hint()

		# Eliminate one wrong option for MCQ or Bug Hunt if possible
		if (q.get("type") == "multiple_choice" or q.get("type") == "bug_hunt") and mcq_option_buttons.size() > 1:
			var correct_idx: int = int(q.get("correct_line", 0)) if q.get("type") == "bug_hunt" else int(q.get("correct_index", 0))
			for i in range(mcq_option_buttons.size()):
				if i != correct_idx and not mcq_option_buttons[i].disabled:
					mcq_option_buttons[i].disabled = true
					mcq_option_buttons[i].text = "✅ [VERIFIED CLEAN] " + mcq_option_buttons[i].text if q.get("type") == "bug_hunt" else "❌ " + mcq_option_buttons[i].text
					break

		if hint_message:
			hint_message.text = q.get("hint", "Master PyWizard says: Check your variable assignment syntax.")
	else:
		if hint_message:
			hint_message.text = "You have exhausted your hint tokens for this expedition! Trust your Python instincts."

	hint_modal_overlay.visible = true
	var hint_card = hint_modal_overlay.find_child("HintCard", true, false) as Control
	if hint_card:
		hint_card.scale = Vector2(0.92, 0.92)
		hint_card.pivot_offset = hint_card.size / 2.0
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(hint_card, "scale", Vector2.ONE, 0.25)
	var wiz_port = hint_modal_overlay.find_child("SpeakerPortrait", true, false) as TextureRect
	if wiz_port:
		wiz_port.scale = Vector2(0.85, 0.85)
		wiz_port.pivot_offset = wiz_port.size / 2.0
		var p_tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		p_tw.tween_property(wiz_port, "scale", Vector2.ONE, 0.28)

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
	BadgeManager.check_all_badges({
		"no_hints_used": (_hints_used_this_battle == 0),
		"code_streak": max_streak
	})

	# Populate Victory Overlay
	var b_upper = "LORD SEGFAULT, THE NULL SOVEREIGN" if level_num == 6 else ("IGNIS-PY, THE GUARDIAN OF PYTHONIA" if level_num == 5 else ("VEKTOR-ZERO" if level_num == 4 else ("LAMBDA-PRIME" if level_num == 3 else ("CHRONOS-IF" if level_num == 2 else "NULLBYTE"))))
	victory_title.text = "👑 PYTHONIA RESTORED: %s PURGED!" % b_upper if level_num == 6 else ("🏆 BOSS DEFEATED: %s!" % b_upper if level_num == 5 else "🏆 BOSS DEFEATED: %s SHATTERED!" % b_upper)
	acc_value.text = "%.1f%%" % accuracy
	var mult: float = min(2.0, 1.0 + (max_streak * 0.1))
	streak_value.text = "%d (x%.1f Max)" % [max_streak, mult]
	time_value.text = "+%d pts (%02d:%02d)" % [time_bonus, int(elapsed_time)/60, int(elapsed_time)%60]
	score_value.text = "%d pts" % final_score
	xp_value.text = "+%d XP" % total_xp
	rank_label.text = title_rank

	if replay_button:
		replay_button.text = "🌍 Back to World %d" % level_num
	if level_select_btn:
		if level_num < 5:
			level_select_btn.text = "🗺️ Go to World %d ➔" % (level_num + 1)
		elif level_num == 5:
			level_select_btn.text = "🎬 The Awakening • Plot Twist ➔"
		else:
			level_select_btn.text = "👑 Save Princess Ada • Return to Map"

	if bottom_dialog_bar and bottom_dialog_bar.has_method("play_boss_outro"):
		bottom_dialog_bar.play_boss_outro(level_num, true)
		await bottom_dialog_bar.dialog_finished
	if not is_inside_tree():
		return

	victory_overlay.visible = true

func _apply_option_style(btn: Button, is_selected: bool) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.set_border_width_all(2)

	if is_selected:
		style.bg_color = Color("#2A184E")
		style.border_color = Color("#F59E0B")
		btn.add_theme_color_override("font_color", Color("#FCD34D"))
	else:
		style.bg_color = Color("#140D2B")
		style.border_color = Color("#4C2A85")
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

func _on_settings_pressed() -> void:
	if settings_modal and settings_modal.has_method("open_settings"):
		settings_modal.open_settings()

func _apply_settings() -> void:
	var font_size_key: String = str(SaveManager.get_setting("code_font_size", "medium"))
	var px: int = 14
	if font_size_key == "small":
		px = 12
	elif font_size_key == "large":
		px = 18
	if code_label:
		code_label.add_theme_font_size_override("normal_font_size", px)
		code_label.add_theme_font_size_override("bold_font_size", px)
		code_label.add_theme_font_size_override("italics_font_size", px)
		code_label.add_theme_font_size_override("mono_font_size", px)

func _on_quit_pressed() -> void:
	SaveManager.skip_world_intro = true
	var cur_lvl: int = int(SaveManager.user_profile.get("current_level", 1))
	if cur_lvl == 6:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_6)
	elif cur_lvl == 5:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_5)
	elif cur_lvl == 4:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_4)
	elif cur_lvl == 3:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_3)
	elif cur_lvl == 2:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_2)
	else:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_1)

# -------------------------------------------------------------------------
# WORLD 6: THE 5 GENERALS' SIEGE ASSIST BAR
# -------------------------------------------------------------------------
func _setup_generals_assist_bar(cur_lvl: int) -> void:
	if generals_assist_bar and is_instance_valid(generals_assist_bar):
		generals_assist_bar.queue_free()
		generals_assist_bar = null
	general_assist_buttons.clear()
	assist_status_label = null

	if cur_lvl != 6:
		return

	var card_vbox = get_node_or_null("LayoutVBox/SplitArea/CodePanel/ScrollContainer/CardVBox") as VBoxContainer
	if not card_vbox:
		return

	generals_assist_bar = PanelContainer.new()
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.11, 0.06, 0.22, 0.96)
	bar_style.border_color = Color("#C084FC")
	bar_style.set_border_width_all(2)
	bar_style.set_corner_radius_all(10)
	bar_style.content_margin_left = 12.0
	bar_style.content_margin_right = 12.0
	bar_style.content_margin_top = 8.0
	bar_style.content_margin_bottom = 8.0
	generals_assist_bar.add_theme_stylebox_override("panel", bar_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	generals_assist_bar.add_child(vbox)

	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(header_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "⚔️ 5 GENERALS' SIEGE ASSISTS (Click a General to Unleash Their Power!):"
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", Color("#FDE047"))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)

	assist_status_label = Label.new()
	assist_status_label.text = "Ready"
	assist_status_label.add_theme_font_size_override("font_size", 11)
	assist_status_label.add_theme_color_override("font_color", Color("#E9D5FF"))
	header_hbox.add_child(assist_status_label)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_hbox)

	var assists_cfg = [
		{"id": "nullbyte", "label": "🟢 NullByte: 50/50 Purge", "color": Color("#10B981"), "bg": Color("#064E3B")},
		{"id": "chronos", "label": "🔵 Chronos: Time Shield", "color": Color("#38BDF8"), "bg": Color("#0C4A6E")},
		{"id": "lambda", "label": "🟣 Lambda: 2x Overcharge", "color": Color("#C084FC"), "bg": Color("#3B0764")},
		{"id": "vektor", "label": "🟠 Vektor: Auto-Lock", "color": Color("#F59E0B"), "bg": Color("#451A03")},
		{"id": "ignis", "label": "🔴 Ignis: Nova & Heal", "color": Color("#FB7185"), "bg": Color("#4C0519")}
	]

	for cfg in assists_cfg:
		var btn := Button.new()
		btn.text = cfg["label"]
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 34)
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", Color("#FFFFFF"))

		var st := StyleBoxFlat.new()
		st.bg_color = cfg["bg"]
		st.border_color = cfg["color"]
		st.set_border_width_all(2)
		st.set_corner_radius_all(6)
		st.content_margin_left = 6.0
		st.content_margin_right = 6.0
		btn.add_theme_stylebox_override("normal", st)

		var st_hov := st.duplicate() as StyleBoxFlat
		st_hov.bg_color = (cfg["bg"] as Color).lightened(0.2)
		btn.add_theme_stylebox_override("hover", st_hov)
		btn.add_theme_stylebox_override("pressed", st)

		var gen_id: String = cfg["id"]
		btn.pressed.connect(func(): _use_general_assist(gen_id))
		btn_hbox.add_child(btn)
		general_assist_buttons[gen_id] = btn

	card_vbox.add_child(generals_assist_bar)
	var ans_idx: int = answer_area.get_index()
	card_vbox.move_child(generals_assist_bar, ans_idx)
	_refresh_generals_assist_bar()

func _refresh_generals_assist_bar() -> void:
	for gen_id in general_assist_buttons.keys():
		var btn: Button = general_assist_buttons[gen_id]
		if not is_instance_valid(btn):
			continue
		var used: bool = general_assists_used.get(gen_id, false)
		btn.disabled = used
		btn.modulate = Color(0.5, 0.5, 0.5, 0.75) if used else Color.WHITE

	if assist_status_label:
		var active_buffs: PackedStringArray = []
		if chronos_shield_active:
			active_buffs.append("🛡️ Time Shield Active")
		if lambda_overcharge_active:
			active_buffs.append("⚡ 2x Overcharge Active")
		assist_status_label.text = "  •  ".join(active_buffs) if active_buffs.size() > 0 else "All 5 Generals Standing By"

func _use_general_assist(gen_id: String) -> void:
	if is_evaluating or general_assists_used.get(gen_id, false):
		return
	var questions: Array = level_data.get("questions", [])
	if current_question_index >= questions.size():
		return
	var q: Dictionary = questions[current_question_index]
	var q_type: String = q.get("type", "multiple_choice")

	general_assists_used[gen_id] = true

	if gen_id == "nullbyte":
		# Eliminate up to 2 wrong choices or place first block in syntax_ordering
		var purged_count: int = 0
		if q_type == "multiple_choice" or q_type == "bug_hunt":
			var correct_idx: int = int(q.get("correct_line", 0)) if q_type == "bug_hunt" else int(q.get("correct_index", 0))
			for i in range(mcq_option_buttons.size()):
				if i != correct_idx and not mcq_option_buttons[i].disabled and purged_count < 2:
					mcq_option_buttons[i].disabled = true
					mcq_option_buttons[i].text = "❌ [PURGED BY NULLBYTE] " + mcq_option_buttons[i].text
					purged_count += 1
		elif q_type == "code_completion":
			var correct_str: String = str(q.get("correct_answer", ""))
			for b in mcq_option_buttons:
				if b.text != correct_str and not b.disabled and purged_count < 2:
					b.disabled = true
					b.text = "❌ " + b.text
					purged_count += 1
		elif q_type == "syntax_ordering":
			var seq: Array = q.get("correct_sequence", [])
			if seq.size() > 0 and selected_ordering.size() < seq.size():
				var next_req: int = int(seq[selected_ordering.size()])
				if next_req < mcq_option_buttons.size():
					_on_order_block_clicked(next_req, mcq_option_buttons[next_req], q)
		if visual_stage and visual_stage.has_method("play_general_assist_effect"):
			visual_stage.play_general_assist_effect("🟢 NULLBYTE ASSIST: 50/50 Glitch Purge!", Color("#10B981"))

	elif gen_id == "chronos":
		chronos_shield_active = true
		if visual_stage and visual_stage.has_method("play_general_assist_effect"):
			visual_stage.play_general_assist_effect("🔵 CHRONOS ASSIST: Temporal Shield Activated!", Color("#38BDF8"))

	elif gen_id == "lambda":
		lambda_overcharge_active = true
		if visual_stage and visual_stage.has_method("play_general_assist_effect"):
			visual_stage.play_general_assist_effect("🟣 LAMBDA ASSIST: Next Spell 2x Score & +150 XP!", Color("#C084FC"))

	elif gen_id == "vektor":
		# Auto-lock the correct option / bug line / next 2 sequence blocks
		if q_type == "multiple_choice":
			var c_idx: int = int(q.get("correct_index", 0))
			if c_idx < mcq_option_buttons.size():
				_on_mcq_option_selected(c_idx, mcq_option_buttons[c_idx])
		elif q_type == "code_completion":
			var c_tok: String = str(q.get("correct_answer", ""))
			for b in mcq_option_buttons:
				if b.text == c_tok:
					_on_completion_option_selected(c_tok, b, q)
					break
		elif q_type == "bug_hunt":
			var c_line: int = int(q.get("correct_line", 0))
			if c_line < mcq_option_buttons.size():
				_on_bug_line_selected(c_line, mcq_option_buttons[c_line], q)
		elif q_type == "syntax_ordering":
			var seq: Array = q.get("correct_sequence", [])
			for _step in range(2):
				if selected_ordering.size() < seq.size():
					var next_idx: int = int(seq[selected_ordering.size()])
					if next_idx < mcq_option_buttons.size() and not mcq_option_buttons[next_idx].disabled:
						_on_order_block_clicked(next_idx, mcq_option_buttons[next_idx], q)
		if visual_stage and visual_stage.has_method("play_general_assist_effect"):
			visual_stage.play_general_assist_effect("🟠 VEKTOR ASSIST: Matrix Solution Locked!", Color("#F59E0B"))

	elif gen_id == "ignis":
		SaveManager.user_profile["hint_tokens"] = int(SaveManager.user_profile.get("hint_tokens", 5)) + 1
		SaveManager.save_local_profile()
		if visual_stage and visual_stage.has_method("play_general_assist_effect"):
			visual_stage.play_general_assist_effect("🔴 IGNIS-PY NOVA: -50 Boss HP & +35 Hero HP!", Color("#FB7185"), 35, 50)
		update_hud()

	_refresh_generals_assist_bar()

func _on_return_current_world_pressed() -> void:
	var level_num: int = int(level_data.get("level_id", SaveManager.user_profile.get("current_level", 1)))
	SaveManager.user_profile["current_level"] = level_num
	SaveManager.skip_world_intro = true
	SaveManager.save_local_profile()
	_on_quit_pressed()

func _on_go_next_world_pressed() -> void:
	var level_num: int = int(level_data.get("level_id", SaveManager.user_profile.get("current_level", 1)))
	if level_num == 5:
		# Beat World 5 -> Play Cutscene 2 (The Plot Twist)!
		SceneManager.change_scene_with_loading("res://scenes/ui/CutscenePlotTwist.tscn")
		return
	elif level_num >= 6:
		SaveManager.user_profile["segfault_beaten"] = true
		SaveManager.user_profile["game_completed"] = true
		SaveManager.user_profile["cutscene_epilogue_unlocked"] = true
		SaveManager.user_profile["current_level"] = 6
		SaveManager.save_local_profile()
		SceneManager.change_scene_with_loading(SceneManager.CUTSCENE_EPILOGUE)
		return
	var next_lvl: int = min(6, level_num + 1)
	SaveManager.user_profile["current_level"] = level_num
	SaveManager.pending_map_advance_to = next_lvl
	SaveManager.save_local_profile()
	SceneManager.change_scene_with_loading(SceneManager.LEVEL_SELECT)

func dev_auto_solve_phase() -> void:
	if bottom_dialog_bar and bottom_dialog_bar.has_method("is_dialog_active") and bottom_dialog_bar.is_dialog_active():
		bottom_dialog_bar._on_skip_pressed()
		return
	if is_evaluating or victory_overlay.visible:
		return
	if feedback_overlay.visible:
		_on_next_question_pressed()
		return
	var questions: Array = level_data.get("questions", [])
	if current_question_index >= questions.size():
		return
	var q: Dictionary = questions[current_question_index]
	var q_type: String = q.get("type", "multiple_choice")
	if q_type == "multiple_choice":
		current_selected_answer = int(q.get("correct_index", 0))
	elif q_type == "code_completion":
		current_selected_answer = str(q.get("correct_answer", ""))
	elif q_type == "syntax_ordering":
		selected_ordering.clear()
		for idx in q.get("correct_sequence", []):
			selected_ordering.append(int(idx))
	elif q_type == "bug_hunt":
		current_selected_answer = int(q.get("correct_line", 0))
	_on_submit_pressed()
