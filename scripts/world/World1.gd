# res://scripts/world/World1.gd
extends Node2D

@onready var player: CharacterBody2D = %Player
@onready var joystick: Control = %VirtualJoystick
@onready var quest_dialog: Control = %QuestDialogModal
@onready var quest_text: Label = %QuestText
@onready var accept_btn: Button = %AcceptButton
@onready var decline_btn: Button = %DeclineButton
@onready var hud_back_btn: Button = %BackToSelectButton
@onready var area_title_label: Label = %AreaTitleLabel

# Shrine & Codex UI Nodes
@onready var shrine_tracker_label: Label = %ShrineTrackerLabel
@onready var shrine_modal: ColorRect = %ShrineModal
@onready var shrine_modal_card: PanelContainer = %ShrineModalCard
@onready var shrine_modal_icon: Label = %ShrineModalIcon
@onready var shrine_modal_title: Label = %ShrineModalTitle
@onready var shrine_modal_topic: Label = %ShrineModalTopic
@onready var shrine_lesson_text: RichTextLabel = %ShrineLessonText
@onready var shrine_question_label: RichTextLabel = %ShrineQuestionLabel
@onready var shrine_options_container: VBoxContainer = %ShrineOptionsContainer
@onready var shrine_feedback_label: Label = %ShrineFeedbackLabel
@onready var shrine_action_btn: Button = %ShrineActionBtn
@onready var shrine_close_btn: Button = %ShrineCloseBtn

# Lore Modal Nodes
@onready var lore_modal: ColorRect = %LoreModal
@onready var lore_card: PanelContainer = %LoreCard
@onready var lore_title_label: Label = %LoreTitleLabel
@onready var lore_text_label: Label = %LoreTextLabel
@onready var lore_xp_label: Label = %LoreXPLabel
@onready var lore_close_btn: Button = %LoreCloseBtn

# Toast Notification
@onready var toast_panel: PanelContainer = %ToastPanel
@onready var toast_label: Label = %ToastLabel

# World Entities
@onready var shrine_numbers: Area2D = $YSortEntities/Shrines/ShrineNumbers
@onready var shrine_strings: Area2D = $YSortEntities/Shrines/ShrineStrings
@onready var shrine_booleans: Area2D = $YSortEntities/Shrines/ShrineBooleans
@onready var gate_rune_1: Sprite2D = $YSortEntities/TrialGate/Rune1
@onready var gate_rune_2: Sprite2D = $YSortEntities/TrialGate/Rune2
@onready var gate_rune_3: Sprite2D = $YSortEntities/TrialGate/Rune3
@onready var gate_particles: CPUParticles2D = $YSortEntities/TrialGate/GateParticles

# State variables
var active_shrine_id: String = ""
var current_shrine_q_idx: int = 0
var shrine_question_answered: bool = false
var selected_option_idx: int = -1
var active_dialog_mode: String = "boss" # "boss" or npc_id
var toast_tween: Tween

const NPCS_DATA: Dictionary = {
	"npc_farmer_bob": {
		"name": "Farmer Bob • Harvest Variable Keeper",
		"icon": "🌾",
		"xp": 40,
		"dialog": "Howdy, Adventurer Alex! Welcome to Variable Valley!\n\nOut here on the farm, I store my harvest counts inside Python variables like:\n  wheat_bushels = 120\n  apple_price = 2.50\n\nRemember my golden rule: Variable names can use letters, numbers, and underscores (_), but they can NEVER start with a number or have spaces! Take this Hint Token and XP for the road!"
	},
	"npc_scout_lyra": {
		"name": "Scout Lyra • Royal String Pathfinder",
		"icon": "🏹",
		"xp": 40,
		"dialog": "Well met by the river, Alex! I've been charting the Southeast Shrine of Words.\n\nWhenever you store text in Python—called a 'str' (string)—you MUST wrap it in single or double quotes:\n  realm = 'Pythonia'\n  print(realm)\n\nIf you forget the quotes, Python thinks the word is another variable name and throws a NameError! Here, take a Hint Token for your journey!"
	},
	"npc_blacksmith_torin": {
		"name": "Runesmith Torin • Master of Boolean Logic",
		"icon": "🔨",
		"xp": 40,
		"dialog": "Hail, young coder! Hear the ring of my anvil? In the Northeast Shrine of Truth, only pure Boolean logic survives!\n\nA 'bool' variable holds only two states: True or False—and their first letter MUST be capitalized!\nComparisons forge booleans automatically:\n  shield_power = 80\n  is_strong = shield_power > 50  # Evaluates to True!\n\nAwaken all 3 Shrines to unseal the Northern Boss Gate, where NullByte the Golem awaits!"
	}
}

const SHRINES_DATA: Dictionary = {
	"shrine_numbers": {
		"title": "Shrine of Numbers",
		"icon": "🔢",
		"color": Color(0.25, 0.75, 1.0),
		"topic": "Integers & Floats (int / float)",
		"lesson": "[b]Numbers in Python[/b] come in two foundational forms:\n• [b]int[/b] (Integer): Whole numbers without decimals like [code]health = 100[/code] or [code]arrows = -5[/code].\n• [b]float[/b] (Floating-Point): Numbers with a decimal point like [code]speed = 3.75[/code] or [code]rate = 2.0[/code].\n• Basic math operators: [code]+[/code] (add), [code]-[/code] (subtract), [code]*[/code] (multiply), [code]/[/code] (divide).",
		"xp": 100,
		"questions": [
			{
				"question": "Which of the following variables stores a [b]float[/b]?",
				"options": [
					"gold = 50",
					"gem_weight = 3.75",
					"player_level = '1'",
					"is_active = True"
				],
				"correct_index": 1,
				"explanation": "'gem_weight = 3.75' has a decimal point, making it a floating-point number (float)!"
			},
			{
				"question": "Which statement correctly assigns the integer [b]250[/b] to a variable named [code]mana_pool[/code]?",
				"options": [
					"int mana_pool = 250",
					"mana_pool = 250",
					"mana_pool = '250'",
					"250 = mana_pool"
				],
				"correct_index": 1,
				"explanation": "Python uses dynamic typing: variable name on the left, '=' in the middle, and raw number on the right!"
			},
			{
				"question": "Which of these is a [b]VALID[/b] Python variable name for storing your potion count?",
				"options": [
					"1st_potion = 5",
					"potion-count = 5",
					"potion_count_1 = 5",
					"potion count = 5"
				],
				"correct_index": 2,
				"explanation": "Variable names can contain letters, numbers, and underscores (_), but cannot start with a number or use spaces/hyphens!"
			},
			{
				"question": "What value is stored in [code]total_damage[/code] after executing:\n[code]base = 20\nbonus = 15\ntotal_damage = base + bonus[/code]",
				"options": [
					"35",
					"'20 + 15'",
					"2015",
					"base + bonus"
				],
				"correct_index": 0,
				"explanation": "Python evaluates 'base + bonus' (20 + 15) and stores the resulting integer 35 in total_damage!"
			}
		]
	},
	"shrine_strings": {
		"title": "Shrine of Words",
		"icon": "📜",
		"color": Color(0.3, 0.9, 0.5),
		"topic": "Strings & Text Output (str & print)",
		"lesson": "Text in Python is called a [b]str[/b] (string) and must be enclosed in quotes:\n• [code]hero_name = 'Alex'[/code] or [code]spell = \"Fireball\"[/code]\n• Use [code]+[/code] to join (concatenate) strings: [code]'Py' + 'Quest'[/code] ➔ [code]'PyQuest'[/code].\n• Use [code]print()[/code] to output values to the screen.",
		"xp": 100,
		"questions": [
			{
				"question": "Which line correctly assigns a string to the variable [code]title[/code]?",
				"options": [
					"title = Apprentice",
					"title = 'Apprentice'",
					"title = <Apprentice>",
					"string title = 'Apprentice'"
				],
				"correct_index": 1,
				"explanation": "Text wrapped in single or double quotes like 'Apprentice' creates a valid string!"
			},
			{
				"question": "What happens if you write [code]hero = Alex[/code] without quotation marks?",
				"options": [
					"Python automatically converts Alex into a string",
					"Python looks for a variable named Alex (and raises a NameError if undefined)",
					"Python stores the number 0",
					"It prints 'Alex' to the console"
				],
				"correct_index": 1,
				"explanation": "Without quotes, Python treats 'Alex' as an identifier (variable name) rather than text!"
			},
			{
				"question": "What is displayed by executing:\n[code]part1 = \"Dragon\"\npart2 = \"Slayer\"\nprint(part1 + part2)[/code]",
				"options": [
					"DragonSlayer",
					"part1 + part2",
					"Dragon + Slayer",
					"SyntaxError"
				],
				"correct_index": 0,
				"explanation": "The '+' operator concatenates (joins) two strings directly together into 'DragonSlayer'!"
			},
			{
				"question": "What is the data type of [code]quest_id = \"500\"[/code]?",
				"options": [
					"int (Integer)",
					"float (Floating-point)",
					"str (String)",
					"bool (Boolean)"
				],
				"correct_index": 2,
				"explanation": "Even though 500 looks like a number, wrapping it in quotes (\"500\") makes it a string (str)!"
			}
		]
	},
	"shrine_booleans": {
		"title": "Shrine of Truth",
		"icon": "⚖️",
		"color": Color(0.85, 0.45, 1.0),
		"topic": "Booleans & Logic (bool & comparisons)",
		"lesson": "A [b]bool[/b] (boolean) represents truth in Python and has only two possible values:\n• [b]True[/b] or [b]False[/b] (always capitalized!)\n• Comparison operators produce booleans: [code]>[/code] (greater), [code]<[/code] (less), [code]==[/code] (equal to), [code]!=[/code] (not equal to).",
		"xp": 100,
		"questions": [
			{
				"question": "Which of the following is a valid [b]boolean[/b] assignment in Python?",
				"options": [
					"gate_open = true",
					"gate_open = True",
					"gate_open = 'True'",
					"gate_open = TRUE"
				],
				"correct_index": 1,
				"explanation": "In Python, boolean keywords must have an uppercase first letter: True and False!"
			},
			{
				"question": "What is the result of evaluating [code]print(15 < 7)[/code]?",
				"options": [
					"True",
					"False",
					"Error",
					"15 < 7"
				],
				"correct_index": 1,
				"explanation": "15 is not less than 7, so Python evaluates the comparison to False!"
			},
			{
				"question": "Which operator checks if two values are [b]equal[/b] in Python (returning True or False)?",
				"options": [
					"=",
					"==",
					"===",
					":="
				],
				"correct_index": 1,
				"explanation": "Single '=' assigns a value to a variable, whereas double '==' compares two values for equality!"
			},
			{
				"question": "Given [code]keys = 3[/code], what is stored in [code]can_unlock[/code] after running:\n[code]can_unlock = (keys == 3)[/code]",
				"options": [
					"3",
					"True",
					"False",
					"'keys == 3'"
				],
				"correct_index": 1,
				"explanation": "Since keys is 3, the comparison 'keys == 3' evaluates to the boolean value True!"
			}
		]
	}
}

func _ready() -> void:
	# Hide overlays by default
	if quest_dialog:
		quest_dialog.visible = false
	if shrine_modal:
		shrine_modal.visible = false
	if lore_modal:
		lore_modal.visible = false
	if toast_panel:
		toast_panel.visible = false
		
	# Setup Player Camera bounds & controls
	if player:
		if player.has_method("set_joystick") and joystick:
			player.set_joystick(joystick)
		var cam = player.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.limit_left = 0
			cam.limit_top = 0
			cam.limit_right = 2400
			cam.limit_bottom = 1350
			cam.position_smoothing_enabled = true
			cam.position_smoothing_speed = 5.0
			
	# Connect Button Signals
	if accept_btn and not accept_btn.pressed.is_connected(_on_accept_quest):
		accept_btn.pressed.connect(_on_accept_quest)
	if decline_btn and not decline_btn.pressed.is_connected(_on_close_quest_dialog):
		decline_btn.pressed.connect(_on_close_quest_dialog)
	if hud_back_btn and not hud_back_btn.pressed.is_connected(_on_back_to_select):
		hud_back_btn.pressed.connect(_on_back_to_select)
		
	if shrine_close_btn and not shrine_close_btn.pressed.is_connected(_on_close_shrine_modal):
		shrine_close_btn.pressed.connect(_on_close_shrine_modal)
	if shrine_action_btn and not shrine_action_btn.pressed.is_connected(_on_shrine_action):
		shrine_action_btn.pressed.connect(_on_shrine_action)
		
	if lore_close_btn and not lore_close_btn.pressed.is_connected(_on_close_lore_modal):
		lore_close_btn.pressed.connect(_on_close_lore_modal)

	# Update Top HUD Title
	var p_name = SaveManager.user_profile.get("full_name", "Adventurer Alex")
	if area_title_label:
		area_title_label.text = "📍 Variable Valley  |  %s" % p_name
		
	# Initialize Shrine & NPC States from SaveData
	_refresh_all_shrine_states()
	_refresh_all_npc_states()

	# Play World 1 Valley Background Music
	AudioManager.play_bgm_by_path("res://assets/audio/world1_music.mp3")

var boss_anim_timer: float = 0.0
func _process(delta: float) -> void:
	boss_anim_timer += delta
	var boss_statue = get_node_or_null("YSortEntities/TrialGate/BossStatue") as Sprite2D
	if boss_statue and boss_statue.hframes >= 6:
		boss_statue.frame = int(boss_anim_timer * 5.0) % 6

	# Gently bob & sway water lilies in the flowing river current
	var l1 = get_node_or_null("BackgroundLandscape/WaterLillies1") as Sprite2D
	var l2 = get_node_or_null("BackgroundLandscape/WaterLillies2") as Sprite2D
	var l3 = get_node_or_null("BackgroundLandscape/WaterLillies3") as Sprite2D
	if l1:
		l1.position = Vector2(1210.0 + sin(boss_anim_timer * 2.0) * 3.5, 210.0 + cos(boss_anim_timer * 2.8) * 4.5)
	if l2:
		l2.position = Vector2(1290.0 + sin(boss_anim_timer * 2.0 + 2.0) * 3.5, 720.0 + cos(boss_anim_timer * 2.8 + 1.5) * 4.5)
	if l3:
		l3.position = Vector2(1310.0 + sin(boss_anim_timer * 2.0 + 4.0) * 3.5, 1210.0 + cos(boss_anim_timer * 2.8 + 3.0) * 4.5)

# ---------------------------------------------------------
# Shrine System & Multi-Question Logic (Phase 1)
# ---------------------------------------------------------
func _get_cleared_shrines() -> Array:
	var list = SaveManager.user_profile.get("w1_shrines", [])
	if typeof(list) != TYPE_ARRAY:
		list = []
	return list

func _refresh_all_shrine_states() -> void:
	var cleared = _get_cleared_shrines()
	
	if shrine_numbers and shrine_numbers.has_method("set_activated"):
		shrine_numbers.set_activated("shrine_numbers" in cleared)
	if shrine_strings and shrine_strings.has_method("set_activated"):
		shrine_strings.set_activated("shrine_strings" in cleared)
	if shrine_booleans and shrine_booleans.has_method("set_activated"):
		shrine_booleans.set_activated("shrine_booleans" in cleared)
		
	_update_shrine_tracker(cleared.size())
	_update_gate_visuals(cleared)

func _update_shrine_tracker(count: int) -> void:
	if not shrine_tracker_label:
		return
	var cleared = _get_cleared_shrines()
	var icon1 = "🔵" if "shrine_numbers" in cleared else "⚪"
	var icon2 = "🟢" if "shrine_strings" in cleared else "⚪"
	var icon3 = "🟣" if "shrine_booleans" in cleared else "⚪"
	if count >= 3:
		shrine_tracker_label.text = "Shrines: 3/3 [%s %s %s] • ⚔️ BOSS UNSEALED!" % [icon1, icon2, icon3]
	else:
		shrine_tracker_label.text = "Shrines Awakened: %d/3  [%s %s %s]" % [count, icon1, icon2, icon3]

func _update_gate_visuals(cleared: Array) -> void:
	var has_num = "shrine_numbers" in cleared
	var has_str = "shrine_strings" in cleared
	var has_bool = "shrine_booleans" in cleared
	var all_cleared = (cleared.size() >= 3)
	
	if gate_rune_1:
		gate_rune_1.modulate = Color(0.3, 0.8, 1.0, 1.0) if has_num else Color(0.25, 0.3, 0.4, 0.5)
	if gate_rune_2:
		gate_rune_2.modulate = Color(0.3, 1.0, 0.5, 1.0) if has_str else Color(0.25, 0.3, 0.4, 0.5)
	if gate_rune_3:
		gate_rune_3.modulate = Color(0.9, 0.5, 1.0, 1.0) if has_bool else Color(0.25, 0.3, 0.4, 0.5)
		
	if gate_particles:
		gate_particles.emitting = all_cleared

	var portal_aura = get_node_or_null("YSortEntities/TrialGate/PortalAura") as Polygon2D
	if portal_aura:
		portal_aura.color = Color(0.65, 0.25, 0.95, 0.65) if all_cleared else Color(0.2, 0.22, 0.3, 0.45)

	var boss_statue = get_node_or_null("YSortEntities/TrialGate/BossStatue") as Sprite2D
	if boss_statue:
		boss_statue.modulate = Color(1.0, 1.0, 1.0, 1.0) if all_cleared else Color(0.45, 0.45, 0.55, 0.75)

	var gate_banner = get_node_or_null("YSortEntities/TrialGate/GateBanner") as Label
	if gate_banner:
		if all_cleared:
			gate_banner.text = "⚔️ Final Shrine: NullByte's Lair (UNSEALED)"
			gate_banner.add_theme_color_override("font_color", Color(1.0, 0.45, 0.55, 1.0))
		else:
			gate_banner.text = "🔒 Final Boss Shrine (%d/3 Runes)" % cleared.size()
			gate_banner.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65, 1.0))

func open_shrine_dialog(s_id: String) -> void:
	if not SHRINES_DATA.has(s_id):
		return
		
	active_shrine_id = s_id
	current_shrine_q_idx = 0
	shrine_question_answered = false
	selected_option_idx = -1
	
	if player:
		player.can_move = false
	if joystick:
		joystick.visible = false
		
	_render_current_shrine_question()
	shrine_modal.visible = true
	_animate_card_pop(shrine_modal_card)

func _render_current_shrine_question() -> void:
	var s_data = SHRINES_DATA[active_shrine_id]
	var questions: Array = s_data["questions"]
	var total_q: int = questions.size()
	var q_data: Dictionary = questions[current_shrine_q_idx]
	var is_already_cleared = active_shrine_id in _get_cleared_shrines()
	
	selected_option_idx = -1
	shrine_question_answered = false
	
	# Build progress pips e.g. [ 🔵 🔵 ⚪ ⚪ ]
	var pips = ""
	for p in range(total_q):
		if p < current_shrine_q_idx:
			pips += "🟢 "
		elif p == current_shrine_q_idx:
			pips += "🟡 "
		else:
			pips += "⚪ "
			
	shrine_modal_icon.text = s_data["icon"]
	shrine_modal_title.text = s_data["title"]
	shrine_modal_topic.text = "%s  •  Trial %d of %d   [ %s]" % [s_data["topic"], current_shrine_q_idx + 1, total_q, pips]
	shrine_lesson_text.text = s_data["lesson"]
	shrine_question_label.text = "[b]Question %d/%d:[/b] %s" % [current_shrine_q_idx + 1, total_q, q_data["question"]]
	
	for child in shrine_options_container.get_children():
		child.queue_free()
		
	var opts = q_data["options"]
	for i in range(opts.size()):
		var opt_btn = Button.new()
		opt_btn.text = "%c)  %s" % [65 + i, opts[i]]
		opt_btn.custom_minimum_size = Vector2(0, 42)
		opt_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		opt_btn.add_theme_font_size_override("font_size", 14)
		
		var default_style = StyleBoxFlat.new()
		default_style.bg_color = Color(0.12, 0.16, 0.25, 0.95)
		default_style.set_border_width_all(1)
		default_style.border_color = Color(0.25, 0.35, 0.5, 0.8)
		default_style.set_corner_radius_all(6)
		default_style.content_margin_left = 16.0
		opt_btn.add_theme_stylebox_override("normal", default_style)
		
		var idx = i
		opt_btn.pressed.connect(func(): _on_select_shrine_option(idx))
		shrine_options_container.add_child(opt_btn)
		
	if is_already_cleared:
		shrine_feedback_label.text = "✦ Shrine Rune already awakened! You may practice the %d trial questions freely." % total_q
		shrine_feedback_label.modulate = Color(0.4, 0.9, 0.5)
	else:
		shrine_feedback_label.text = "Select the correct answer above (%d/%d to awaken rune)." % [current_shrine_q_idx + 1, total_q]
		shrine_feedback_label.modulate = Color(0.8, 0.85, 0.9)
		
	shrine_action_btn.text = "▶ Check Answer"
	shrine_action_btn.disabled = true

func _on_select_shrine_option(idx: int) -> void:
	if shrine_question_answered:
		return
	selected_option_idx = idx
	var children = shrine_options_container.get_children()
	
	for i in range(children.size()):
		var b = children[i] as Button
		var st = StyleBoxFlat.new()
		st.set_corner_radius_all(6)
		st.content_margin_left = 16.0
		
		if i == idx:
			st.bg_color = Color(0.2, 0.4, 0.7, 1.0)
			st.border_color = Color(0.4, 0.75, 1.0, 1.0)
			st.set_border_width_all(2)
		else:
			st.bg_color = Color(0.12, 0.16, 0.25, 0.95)
			st.border_color = Color(0.25, 0.35, 0.5, 0.8)
			st.set_border_width_all(1)
		b.add_theme_stylebox_override("normal", st)
		
	shrine_action_btn.disabled = false

func _on_shrine_action() -> void:
	if not SHRINES_DATA.has(active_shrine_id):
		return
	var s_data = SHRINES_DATA[active_shrine_id]
	var questions: Array = s_data["questions"]
	var total_q: int = questions.size()
	var q_data: Dictionary = questions[current_shrine_q_idx]
	
	# If already answered correctly and clicking "Next Question ➔"
	if shrine_question_answered:
		if current_shrine_q_idx < total_q - 1:
			current_shrine_q_idx += 1
			_render_current_shrine_question()
		else:
			_on_close_shrine_modal()
		return
		
	# Evaluate current answer
	if selected_option_idx == q_data["correct_index"]:
		shrine_question_answered = true
		shrine_feedback_label.text = "✨ Correct! " + q_data["explanation"]
		shrine_feedback_label.modulate = Color(0.3, 1.0, 0.5)
		
		if current_shrine_q_idx < total_q - 1:
			shrine_action_btn.text = "Next Question (%d/%d) ➔" % [current_shrine_q_idx + 2, total_q]
			shrine_action_btn.disabled = false
		else:
			# Final question of the shrine completed!
			shrine_action_btn.text = "✓ Complete Shrine"
			shrine_action_btn.disabled = false
			
			var cleared = _get_cleared_shrines()
			if active_shrine_id not in cleared:
				cleared.append(active_shrine_id)
				SaveManager.user_profile["w1_shrines"] = cleared
				
				var earned_xp = int(s_data["xp"])
				var cur_xp = int(SaveManager.user_profile.get("xp", 0)) + earned_xp
				SaveManager.user_profile["xp"] = cur_xp
				SaveManager.user_profile["player_level"] = max(1, int(cur_xp / 500) + 1)
				SaveManager.save_local_profile()
				
				_refresh_all_shrine_states()
				if cleared.size() >= 3:
					show_toast("🔥 ALL 3 SHRINES AWAKENED! The Final Boss Gate is Unsealed! (+%d XP)" % earned_xp)
				else:
					show_toast("✦ %s Awakened! (%d/3 Runes) +%d XP" % [s_data["title"], cleared.size(), earned_xp])
	else:
		shrine_feedback_label.text = "❌ Not quite! " + q_data["explanation"]
		shrine_feedback_label.modulate = Color(1.0, 0.4, 0.4)

func _on_close_shrine_modal() -> void:
	if shrine_modal:
		shrine_modal.visible = false
	if player:
		player.can_move = true
	if joystick:
		joystick.visible = true

# ---------------------------------------------------------
# Valley NPCs System (Phase 2)
# ---------------------------------------------------------
func _get_talked_npcs() -> Array:
	var list = SaveManager.user_profile.get("w1_npcs", [])
	if typeof(list) != TYPE_ARRAY:
		list = []
	return list

func _refresh_all_npc_states() -> void:
	var talked = _get_talked_npcs()
	var npcs_root = get_node_or_null("YSortEntities/NPCs")
	if not npcs_root:
		return
	for npc in npcs_root.get_children():
		if npc.has_method("set_rewarded") and "npc_id" in npc:
			npc.set_rewarded(npc.npc_id in talked)

func open_npc_dialog(npc_id: String) -> void:
	if not NPCS_DATA.has(npc_id):
		return
	active_dialog_mode = npc_id
	var n_data = NPCS_DATA[npc_id]
	var talked = _get_talked_npcs()
	var already_claimed = npc_id in talked
	
	if player:
		player.can_move = false
	if joystick:
		joystick.visible = false
		
	var speaker_icon = quest_dialog.get_node_or_null("Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerIcon") as Label
	var speaker_name = quest_dialog.get_node_or_null("Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerName") as Label
	if speaker_icon:
		speaker_icon.text = n_data["icon"]
	if speaker_name:
		speaker_name.text = n_data["name"]
		
	quest_text.text = n_data["dialog"]
	decline_btn.text = "Close"
	
	if already_claimed:
		accept_btn.text = "✓ Wisdom Claimed"
		accept_btn.disabled = true
	else:
		accept_btn.text = "🎁 Claim +%d XP & +1 Hint" % int(n_data["xp"])
		accept_btn.disabled = false
		
	if quest_dialog:
		quest_dialog.visible = true
		var card = quest_dialog.get_node_or_null("Center/DialogCard")
		if card:
			_animate_card_pop(card)

# ---------------------------------------------------------
# Lore & Chest System
# ---------------------------------------------------------
func show_lore_modal(title: String, body: String, xp: int) -> void:
	if player:
		player.can_move = false
	if joystick:
		joystick.visible = false
		
	if lore_title_label:
		lore_title_label.text = "📦 " + title
	if lore_text_label:
		lore_text_label.text = body
	if lore_xp_label:
		lore_xp_label.text = "+%d XP Claimed!" % xp
		
	if lore_modal:
		lore_modal.visible = true
		_animate_card_pop(lore_card)
		
	show_toast("Found Secret Lore: +%d XP!" % xp)

func _on_close_lore_modal() -> void:
	if lore_modal:
		lore_modal.visible = false
	if player:
		player.can_move = true
	if joystick:
		joystick.visible = true

# ---------------------------------------------------------
# Toast Notification
# ---------------------------------------------------------
func show_toast(msg: String) -> void:
	if not toast_panel or not toast_label:
		return
	toast_label.text = msg
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	toast_panel.position.y = -50
	
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
		
	toast_tween = create_tween()
	toast_tween.tween_property(toast_panel, "position:y", 20.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.parallel().tween_property(toast_panel, "modulate:a", 1.0, 0.3)
	toast_tween.tween_interval(3.0)
	toast_tween.tween_property(toast_panel, "position:y", -50.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	toast_tween.parallel().tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	toast_tween.tween_callback(func(): toast_panel.visible = false)

# ---------------------------------------------------------
# Final Boss Shrine & Master PyWizard (Phase 3)
# ---------------------------------------------------------
func open_quest_dialog() -> void:
	active_dialog_mode = "boss"
	if player:
		player.can_move = false
	if joystick:
		joystick.visible = false
		
	var speaker_icon = quest_dialog.get_node_or_null("Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerIcon") as Label
	var speaker_name = quest_dialog.get_node_or_null("Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerName") as Label
	if speaker_icon:
		speaker_icon.text = "🧙‍♂️"
	if speaker_name:
		speaker_name.text = "Master PyWizard • Guardian of the Final Shrine"
		
	var cleared = _get_cleared_shrines()
	var raw_stars = SaveManager.user_profile.get("level_stars", {})
	var stars: int = 0
	if typeof(raw_stars) == TYPE_DICTIONARY:
		stars = int(raw_stars.get("1", 0))
	elif typeof(raw_stars) == TYPE_ARRAY and raw_stars.size() > 0:
		stars = int(raw_stars[0])
		
	decline_btn.text = "Return to Valley"
	
	if stars > 0:
		var stars_str = ""
		for s in range(3):
			stars_str += "★" if s < stars else "☆"
		quest_text.text = "Hail, Champion Alex!\nYou have defeated NullByte, the Glitched Variable Golem (Rating: %s)!\n\nWould you like to re-enter the Final Boss Shrine to sharpen your Python spells and achieve a higher score?" % stars_str
		accept_btn.text = "⚔️ Rematch Boss: NullByte"
		accept_btn.disabled = false
	elif cleared.size() >= 3:
		quest_text.text = "Magnificent work, Adventurer Alex!\n\nAll 3 Elemental Shrines (Numbers, Words, and Truth) have been awakened! Their runes have shattered the barrier sealing the Final Shrine!\n\nInside awaits NULLBYTE, THE GLITCHED VARIABLE GOLEM. Cast your Python code spells to deplete its HP and unlock Chapter 2!"
		accept_btn.text = "⚔️ Fight Boss: NullByte Golem!"
		accept_btn.disabled = false
	else:
		var missing: Array = []
		if "shrine_numbers" not in cleared:
			missing.append("• 🔵 Shrine of Numbers (West Clearing)")
		if "shrine_strings" not in cleared:
			missing.append("• 🟢 Shrine of Words (Southeast Across Lower Bridge)")
		if "shrine_booleans" not in cleared:
			missing.append("• 🟣 Shrine of Truth (Northeast Across Upper Bridge)")
			
		quest_text.text = "Halt, young coder! Beyond this gate lies NULLBYTE, THE GLITCHED VARIABLE GOLEM.\n\nThe Final Boss Shrine is sealed by ancient syntax magic (%d/3 Runes Awakened). You must complete all 4 trial questions at each of the remaining shrines to break the seal:\n%s" % [cleared.size(), "\n".join(missing)]
		accept_btn.text = "🔒 Sealed (%d/3 Shrines Awakened)" % cleared.size()
		accept_btn.disabled = true

	if quest_dialog:
		quest_dialog.visible = true
		var card = quest_dialog.get_node_or_null("Center/DialogCard")
		if card:
			_animate_card_pop(card)

func _on_accept_quest() -> void:
	if active_dialog_mode != "boss":
		# Claim NPC reward!
		if NPCS_DATA.has(active_dialog_mode):
			var talked = _get_talked_npcs()
			if active_dialog_mode not in talked:
				talked.append(active_dialog_mode)
				SaveManager.user_profile["w1_npcs"] = talked
				var xp_gain = int(NPCS_DATA[active_dialog_mode]["xp"])
				var cur_xp = int(SaveManager.user_profile.get("xp", 0)) + xp_gain
				SaveManager.user_profile["xp"] = cur_xp
				SaveManager.user_profile["player_level"] = max(1, int(cur_xp / 500) + 1)
				SaveManager.user_profile["hint_tokens"] = int(SaveManager.user_profile.get("hint_tokens", 5)) + 1
				SaveManager.save_local_profile()
				_refresh_all_npc_states()
				show_toast("🎁 +%d XP & +1 Hint Token from %s!" % [xp_gain, NPCS_DATA[active_dialog_mode]["name"].split("•")[0].strip_edges()])
		_on_close_quest_dialog()
		return
		
	# Enter Boss Battle Arena!
	SaveManager.user_profile["current_level"] = 1
	SaveManager.save_local_profile()
	SceneManager.change_scene(SceneManager.LEVEL_GAMEPLAY)

func _on_close_quest_dialog() -> void:
	if quest_dialog:
		quest_dialog.visible = false
	if player:
		player.can_move = true
	if joystick:
		joystick.visible = true

func _on_back_to_select() -> void:
	SceneManager.change_scene(SceneManager.LEVEL_SELECT)

func _animate_card_pop(node: Control) -> void:
	if not node:
		return
	node.scale = Vector2(0.85, 0.85)
	node.pivot_offset = node.size * 0.5
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, 0.25)
