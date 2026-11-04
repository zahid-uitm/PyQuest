# res://scripts/world/World2.gd
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
var active_dialog_mode: String = "boss"
var toast_tween: Tween
var boss_anim_timer: float = 0.0
var trap_state: int = 0 # 0 = SAFE (False), 1 = CHARGING, 2 = ARMED (True)
var trap_cooldown: float = 0.0
var active_terminal_id: String = ""

const NPCS_DATA: Dictionary = {
	"npc_keeper_venn": {
		"name": "Bridge-Keeper Venn • Conditional Engineer",
		"icon": "🔧",
		"xp": 50,
		"dialog": "Careful near the chasm edge, Adventurer Alex! Welcome to the Chamber of Conditions!\n\nBoth suspension bridges across the Abyssal Chasm are locked by laser barriers. Walk up to the glowing Bridge Terminals and use Python 'if / else' checks to verify bridge safety:\n  if chasm_stable == True:\n      unlock_bridge()\n\nAlso watch the glowing Floor Rune Traps! When 'trap_armed == True' (Red), stay back; cross only when 'trap_armed == False' (Cyan)! Take this Hint Token and XP!"
	},
	"npc_weaver_sera": {
		"name": "Chrono-Weaver Sera • Mistress of For-Loops",
		"icon": "⏳",
		"xp": 50,
		"dialog": "Greetings across the chasm, Alex! In the Southeast Shrine of Counting Loops, we weave time using Python's 'for' loop!\n\nInstead of repeating code manually, use 'range(n)' to execute a block exactly 'n' times:\n  for step in range(4):\n      lay_bridge_plank(step)\n\nRemember: 'range(4)' counts from 0 up to 3 (0, 1, 2, 3—four steps total)! Take this Hint Token for your trials!"
	},
	"npc_sentinel_kael": {
		"name": "Sentinel Kael • Guardian of While-Loops",
		"icon": "🛡️",
		"xp": 50,
		"dialog": "Stand firm, coder! Ahead lies the Northeast Shrine of Sentinel Loops, and across the North Bridge waits Chronos-If, The Infinite Loop Warden!\n\nA 'while' loop keeps repeating as long as its condition remains True:\n  while shield_hp > 0:\n      defend_chasm()\n\nAlways update your variable inside a 'while' loop—or use 'break'—otherwise you'll be trapped in an Infinite Loop forever! Take this Hint Token!"
	}
}

const SHRINES_DATA: Dictionary = {
	"shrine_if_else": {
		"title": "Shrine of Branches",
		"icon": "💎",
		"color": Color(0.2, 0.8, 1.0),
		"topic": "Conditional Statements (if / elif / else)",
		"lesson": "[b]Conditional Statements[/b] let your Python code make decisions:\n• [code]if condition:[/code] runs its indented block only when the condition is [code]True[/code].\n• [code]elif other_condition:[/code] checks another branch if previous conditions were [code]False[/code].\n• [code]else:[/code] runs as the fallback when all earlier conditions are [code]False[/code].\n• Every header line must end with a colon ([code]:[/code]) and indent the code below it!",
		"xp": 120,
		"questions": [
			{
				"question": "Which symbol MUST appear at the end of an [code]if[/code], [code]elif[/code], or [code]else[/code] header line in Python?",
				"options": [
					"A semicolon (;)",
					"A colon (:)",
					"Curly braces ({})",
					"An arrow (->)"
				],
				"correct_index": 1,
				"explanation": "In Python, every control structure header ('if', 'elif', 'else', 'for', 'while') ends with a colon (:)!"
			},
			{
				"question": "What will be printed by this conditional check?\n[code]gems = 12\nif gems >= 10:\n    print('Bridge Unlocked')\nelse:\n    print('Locked')[/code]",
				"options": [
					"Bridge Unlocked",
					"Locked",
					"Both messages",
					"Nothing"
				],
				"correct_index": 0,
				"explanation": "Since gems is 12, '12 >= 10' is True, so Python executes the 'if' branch and prints 'Bridge Unlocked'!"
			},
			{
				"question": "Which keyword is used in Python to check an additional condition after an [code]if[/code] statement?",
				"options": [
					"elseif",
					"else if",
					"elif",
					"when"
				],
				"correct_index": 2,
				"explanation": "Python uses 'elif' (short for 'else if') to chain multiple conditional checks together!"
			},
			{
				"question": "How does Python know which lines of code belong inside an [code]if[/code] block?",
				"options": [
					"By surrounding them with parentheses ()",
					"By indenting the lines with spaces (usually 4 spaces)",
					"By ending the block with 'endif'",
					"By writing them all on the same line"
				],
				"correct_index": 1,
				"explanation": "Python uses indentation (4 spaces) to group statements inside conditional and loop blocks!"
			}
		]
	},
	"shrine_for_loops": {
		"title": "Shrine of Counting Loops",
		"icon": "🔁",
		"color": Color(0.25, 0.95, 0.65),
		"topic": "For Loops & range() Iteration",
		"lesson": "[b]For Loops[/b] repeat a block of code a specific number of times or over a sequence:\n• [code]for i in range(5):[/code] repeats the indented block [b]5 times[/b] with [code]i[/code] taking values [code]0, 1, 2, 3, 4[/code].\n• [code]range(start, stop)[/code] counts from [code]start[/code] up to (but not including) [code]stop[/code].",
		"xp": 120,
		"questions": [
			{
				"question": "How many times will [code]print('Step')[/code] execute in this loop?\n[code]for i in range(4):\n    print('Step')[/code]",
				"options": [
					"3 times",
					"4 times",
					"5 times",
					"Infinite times"
				],
				"correct_index": 1,
				"explanation": "'range(4)' generates 4 numbers (0, 1, 2, 3), so the loop body runs exactly 4 times!"
			},
			{
				"question": "What sequence of numbers is generated by [code]range(3)[/code]?",
				"options": [
					"1, 2, 3",
					"0, 1, 2",
					"0, 1, 2, 3",
					"3, 2, 1"
				],
				"correct_index": 1,
				"explanation": "'range(n)' starts at 0 by default and stops just before 'n', producing 0, 1, 2!"
			},
			{
				"question": "What is the value of [code]total[/code] after this loop finishes?\n[code]total = 0\nfor n in range(1, 4):\n    total = total + n[/code]",
				"options": [
					"6",
					"10",
					"4",
					"3"
				],
				"correct_index": 0,
				"explanation": "'range(1, 4)' produces 1, 2, 3. Adding them to total gives 1 + 2 + 3 = 6!"
			},
			{
				"question": "Which header correctly loops through each crystal in a list named [code]crystals[/code]?",
				"options": [
					"for crystal in crystals:",
					"loop crystal from crystals:",
					"foreach (crystal : crystals)",
					"while crystal in crystals:"
				],
				"correct_index": 0,
				"explanation": "'for item in collection:' is Python's clean, readable syntax for iterating over any sequence!"
			}
		]
	},
	"shrine_while_loops": {
		"title": "Shrine of Sentinel Loops",
		"icon": "⏳",
		"color": Color(0.95, 0.75, 0.25),
		"topic": "While Loops, Loop Control & break",
		"lesson": "[b]While Loops[/b] repeat as long as a boolean condition remains [code]True[/code]:\n• [code]while energy > 0:[/code] keeps looping until [code]energy > 0[/code] becomes [code]False[/code].\n• [code]break[/code] immediately exits a loop early when a target condition is met.\n• Always update the condition variable inside the loop to avoid an [b]Infinite Loop[/b]!",
		"xp": 120,
		"questions": [
			{
				"question": "When does a Python [code]while[/code] loop stop repeating?",
				"options": [
					"As soon as its condition evaluates to False (or a 'break' statement runs)",
					"Always after 10 iterations",
					"When the condition evaluates to True",
					"After running exactly once"
				],
				"correct_index": 0,
				"explanation": "A 'while' loop checks its condition before each iteration and stops as soon as the condition is False (or 'break' is executed)!"
			},
			{
				"question": "What causes an [b]Infinite Loop[/b] in this code?\n[code]count = 1\nwhile count <= 5:\n    print(count)[/code]",
				"options": [
					"'count' is never increased inside the loop, so 'count <= 5' stays True forever",
					"The 'while' keyword always loops forever",
					"'count' starts at 1 instead of 0",
					"There is no 'else' branch"
				],
				"correct_index": 0,
				"explanation": "Without 'count = count + 1' inside the loop body, 'count' stays 1 forever and 'count <= 5' never becomes False!"
			},
			{
				"question": "Which Python statement immediately exits a [code]for[/code] or [code]while[/code] loop early?",
				"options": [
					"stop",
					"exit_loop",
					"break",
					"halt"
				],
				"correct_index": 2,
				"explanation": "The 'break' statement immediately terminates the enclosing loop and continues execution after the loop block!"
			},
			{
				"question": "How many times will this [code]while[/code] loop run?\n[code]shields = 3\nwhile shields > 0:\n    shields = shields - 1[/code]",
				"options": [
					"3 times (shields goes 3 ➔ 2 ➔ 1 ➔ 0)",
					"4 times",
					"0 times",
					"Infinite times"
				],
				"correct_index": 0,
				"explanation": "The loop runs for shields = 3, 2, and 1 (3 times total), then stops when shields reaches 0!"
			}
		]
	},
	"bridge_south": {
		"title": "South Chasm Bridge Terminal",
		"icon": "🌉",
		"color": Color(0.2, 0.9, 1.0),
		"topic": "Bridge Safety Protocol (if / and)",
		"lesson": "[b]Chasm Bridge Override:[/b] The Lower Suspension Bridge is sealed by a conditional laser barrier! Execute a 2-step Python safety check to power down the barrier and cross the Abyssal Chasm.",
		"xp": 75,
		"questions": [
			{
				"question": "[b]Step 1:[/b] Which conditional check verifies that [code]bridge_anchored[/code] is equal to [code]True[/code]?",
				"options": [
					"if bridge_anchored == True:",
					"if bridge_anchored = True:",
					"while bridge_anchored != True:",
					"elif bridge_anchored:"
				],
				"correct_index": 0,
				"explanation": "'if bridge_anchored == True:' uses the equality operator (==) and ends with a colon (:)!"
			},
			{
				"question": "[b]Step 2:[/b] Combine two safety checks so the bridge unseals only when [b]BOTH[/b] [code]anchored == True[/code] AND [code]wind < 20[/code]:",
				"options": [
					"if anchored == True and wind < 20:",
					"if anchored == True or wind < 20:",
					"if not anchored == True:",
					"for wind in range(20):"
				],
				"correct_index": 0,
				"explanation": "The 'and' operator requires BOTH conditions to be True! South Chasm Bridge unsealed!"
			}
		]
	},
	"bridge_north": {
		"title": "North Chasm Bridge Terminal",
		"icon": "⚡",
		"color": Color(0.95, 0.78, 0.25),
		"topic": "Suspension Cable Loop Protocol (for / if)",
		"lesson": "[b]North Bridge Override:[/b] The Upper Suspension Bridge requires locking all 4 suspension cables with a [code]for[/code] loop before approaching Chronos-If's Sanctuary!",
		"xp": 75,
		"questions": [
			{
				"question": "[b]Step 1:[/b] Which loop header iterates through all 4 suspension cables ([code]0, 1, 2, 3[/code])?",
				"options": [
					"for cable in range(4):",
					"for cable in 4:",
					"while cable in range(4):",
					"if cable in range(4):"
				],
				"correct_index": 0,
				"explanation": "'for cable in range(4):' iterates 4 times (0, 1, 2, 3) to lock every cable!"
			},
			{
				"question": "[b]Step 2:[/b] Inside the loop, which statement unseals the laser gate when the final cable ([code]cable == 3[/code]) is locked?",
				"options": [
					"if cable == 3:\n    unseal_north_bridge()",
					"else cable == 3:\n    unseal_north_bridge()",
					"for cable == 3:\n    unseal_north_bridge()",
					"while cable = 3:"
				],
				"correct_index": 0,
				"explanation": "Nesting 'if cable == 3:' inside the loop triggers 'unseal_north_bridge()' on the final cable! North Chasm Bridge unsealed!"
			}
		]
	}
}

func _ready() -> void:
	SaveManager.user_profile["current_level"] = 2
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

	# Connect World 2 Exclusive Bridge Terminals & Conditional Traps
	_setup_bridge_terminals()
	_setup_condition_traps()

	var p_name = SaveManager.user_profile.get("full_name", "Adventurer Alex")
	if area_title_label:
		area_title_label.text = "💎 Chamber of Conditions  |  %s" % p_name

	_refresh_all_shrine_states()
	_refresh_all_npc_states()
	_refresh_bridge_states()

	AudioManager.play_bgm_by_path("res://assets/audio/world1_music.mp3")

func _process(delta: float) -> void:
	boss_anim_timer += delta
	if trap_cooldown > 0.0:
		trap_cooldown -= delta

	var boss_statue = get_node_or_null("YSortEntities/TrialGate/BossStatue") as Sprite2D
	if boss_statue and boss_statue.hframes >= 6:
		boss_statue.frame = int(boss_anim_timer * 5.0) % 6

	# Cycle World 2 Conditional Floor Traps (0 = SAFE [2.4s], 1 = CHARGING [1.0s], 2 = ARMED [1.8s])
	var cycle_pos = fmod(boss_anim_timer, 5.2)
	var new_state = 0
	if cycle_pos < 2.4:
		new_state = 0
	elif cycle_pos < 3.4:
		new_state = 1
	else:
		new_state = 2

	if new_state != trap_state:
		trap_state = new_state
		_update_trap_visuals()

	if trap_state == 2 and trap_cooldown <= 0.0:
		_check_player_in_armed_trap()

func _unhandled_input(event: InputEvent) -> void:
	if active_terminal_id != "" and not shrine_modal.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_E or event.is_action_pressed("ui_accept"):
				open_shrine_modal(active_terminal_id)

# ---------------------------------------------------------
# World 2 Exclusive: Chasm Bridge Terminals & Laser Gates
# ---------------------------------------------------------
func _get_unlocked_bridges() -> Array:
	var list = SaveManager.user_profile.get("w2_bridges", [])
	if typeof(list) != TYPE_ARRAY:
		list = []
	return list

func _setup_bridge_terminals() -> void:
	for b_id in ["bridge_south", "bridge_north"]:
		var node_name = "BridgeGateSouth" if b_id == "bridge_south" else "BridgeGateNorth"
		var term_area = get_node_or_null("YSortEntities/" + node_name + "/TerminalArea") as Area2D
		if term_area:
			term_area.body_entered.connect(func(body: Node2D):
				if body.is_in_group("Player"):
					active_terminal_id = b_id
					var pr = term_area.get_node_or_null("PromptLabel") as Label
					if pr:
						pr.visible = true
			)
			term_area.body_exited.connect(func(body: Node2D):
				if body.is_in_group("Player"):
					if active_terminal_id == b_id:
						active_terminal_id = ""
					var pr = term_area.get_node_or_null("PromptLabel") as Label
					if pr:
						pr.visible = false
			)
			term_area.input_event.connect(func(_vp: Node, ev: InputEvent, _idx: int):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					if active_terminal_id == b_id:
						open_shrine_modal(b_id)
			)

func _refresh_bridge_states() -> void:
	var unlocked = _get_unlocked_bridges()
	_apply_bridge_visual("BridgeGateSouth", "bridge_south" in unlocked, "South Chasm Bridge")
	_apply_bridge_visual("BridgeGateNorth", "bridge_north" in unlocked, "North Chasm Bridge")

func _apply_bridge_visual(node_name: String, is_open: bool, label_title: String) -> void:
	var gate_node = get_node_or_null("YSortEntities/" + node_name) as Node2D
	if not gate_node:
		return
	var laser = gate_node.get_node_or_null("LaserBarrier") as Sprite2D
	var col = gate_node.get_node_or_null("BarrierBody/BarrierCol") as CollisionShape2D
	var status_lbl = gate_node.get_node_or_null("TerminalArea/StatusLabel") as Label
	var term_spr = gate_node.get_node_or_null("TerminalArea/TerminalSprite") as Sprite2D

	if laser:
		laser.visible = not is_open
	if col:
		col.set_deferred("disabled", is_open)
	if term_spr:
		term_spr.modulate = Color(0.4, 1.0, 0.75, 1.0) if is_open else Color(1.0, 0.65, 0.75, 1.0)
	if status_lbl:
		if is_open:
			status_lbl.text = "🔓 %s: UNSEALED (True)" % label_title
			status_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.65))
		else:
			status_lbl.text = "🔒 %s: SEALED (Override Required)" % label_title
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.55))

# ---------------------------------------------------------
# World 2 Exclusive: Cycling Conditional Floor Traps
# ---------------------------------------------------------
func _setup_condition_traps() -> void:
	var traps_root = get_node_or_null("YSortEntities/ConditionTraps")
	if not traps_root:
		return
	for trap in traps_root.get_children():
		if trap is Area2D:
			trap.body_entered.connect(func(body: Node2D):
				if body.is_in_group("Player") and trap_state == 2 and trap_cooldown <= 0.0:
					_trigger_trap_zap(trap)
			)
	_update_trap_visuals()

func _update_trap_visuals() -> void:
	var traps_root = get_node_or_null("YSortEntities/ConditionTraps")
	if not traps_root:
		return
	for trap in traps_root.get_children():
		var spr = trap.get_node_or_null("TrapSprite") as Sprite2D
		var lbl = trap.get_node_or_null("TrapLabel") as Label
		if spr and spr.hframes >= 3:
			spr.frame = trap_state
		if lbl:
			if trap_state == 0:
				lbl.text = "🟢 armed == False (SAFE)"
				lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0))
			elif trap_state == 1:
				lbl.text = "🟡 elif charging: CAUTION"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			else:
				lbl.text = "🔴 if armed == True: SPIKES!"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.45))

func _check_player_in_armed_trap() -> void:
	var traps_root = get_node_or_null("YSortEntities/ConditionTraps")
	if not traps_root or not player:
		return
	for trap in traps_root.get_children():
		if trap is Area2D and trap.overlaps_body(player):
			_trigger_trap_zap(trap)
			break

func _trigger_trap_zap(trap: Node2D) -> void:
	trap_cooldown = 1.2
	if player:
		var push_dir = (player.global_position - trap.global_position).normalized()
		if push_dir.length() < 0.1:
			push_dir = Vector2(0, 1)
		var target_pos = player.global_position + push_dir * 52.0
		player.modulate = Color(2.0, 0.35, 0.45)
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(player, "global_position", target_pos, 0.2)
		tw.parallel().tween_property(player, "modulate", Color.WHITE, 0.35)
	show_toast("⚡ Conditional Trap Triggered! (if armed == True:) Cross when SAFE (False)!")

# ---------------------------------------------------------
# Shrine System & Multi-Question Logic
# ---------------------------------------------------------
func _get_cleared_shrines() -> Array:
	var list = SaveManager.user_profile.get("w2_shrines", [])
	if typeof(list) != TYPE_ARRAY:
		list = []
	return list

func _refresh_all_shrine_states() -> void:
	var cleared = _get_cleared_shrines()

	if shrine_numbers and shrine_numbers.has_method("set_activated"):
		shrine_numbers.set_activated("shrine_if_else" in cleared)
	if shrine_strings and shrine_strings.has_method("set_activated"):
		shrine_strings.set_activated("shrine_for_loops" in cleared)
	if shrine_booleans and shrine_booleans.has_method("set_activated"):
		shrine_booleans.set_activated("shrine_while_loops" in cleared)

	_update_shrine_tracker(cleared.size())
	_update_gate_visuals(cleared)

func _update_shrine_tracker(count: int) -> void:
	if not shrine_tracker_label:
		return
	var cleared = _get_cleared_shrines()
	var bridges = _get_unlocked_bridges()
	var icon1 = "💎" if "shrine_if_else" in cleared else "⚪"
	var icon2 = "🟢" if "shrine_for_loops" in cleared else "⚪"
	var icon3 = "🟡" if "shrine_while_loops" in cleared else "⚪"
	if count >= 3:
		shrine_tracker_label.text = "✨ All 3 Shrines Awakened! [%s %s %s] ➔ Challenge Boss Chronos-If!" % [icon1, icon2, icon3]
		shrine_tracker_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.6))
	else:
		shrine_tracker_label.text = "Shrines: %d/3 [%s %s %s]  |  Bridges Unsealed: %d/2" % [count, icon1, icon2, icon3, bridges.size()]
		shrine_tracker_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))

func _update_gate_visuals(cleared: Array) -> void:
	if gate_rune_1:
		gate_rune_1.modulate = Color(0.25, 0.85, 1.0, 1.0) if "shrine_if_else" in cleared else Color(0.25, 0.3, 0.4, 0.5)
	if gate_rune_2:
		gate_rune_2.modulate = Color(0.3, 0.95, 0.55, 1.0) if "shrine_for_loops" in cleared else Color(0.25, 0.3, 0.4, 0.5)
	if gate_rune_3:
		gate_rune_3.modulate = Color(0.95, 0.78, 0.25, 1.0) if "shrine_while_loops" in cleared else Color(0.25, 0.3, 0.4, 0.5)
	if gate_particles:
		gate_particles.emitting = (cleared.size() >= 3)

	var gate_banner = get_node_or_null("YSortEntities/TrialGate/GateBanner") as Label
	var portal_aura = get_node_or_null("YSortEntities/TrialGate/PortalAura") as Polygon2D
	var boss_statue = get_node_or_null("YSortEntities/TrialGate/BossStatue") as Sprite2D
	if cleared.size() >= 3:
		if gate_banner:
			gate_banner.text = "⚔️ BOSS UNSEALED: Chronos-If, The Loop Warden"
			gate_banner.add_theme_color_override("font_color", Color(0.35, 1.0, 0.65))
		if portal_aura:
			portal_aura.color = Color(0.15, 0.75, 1.0, 0.65)
		if boss_statue:
			boss_statue.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		if gate_banner:
			gate_banner.text = "🔒 FINAL BOSS SHRINE: Sealed (%d/3 Runes)" % cleared.size()
			gate_banner.add_theme_color_override("font_color", Color(1.0, 0.65, 0.35))
		if portal_aura:
			portal_aura.color = Color(0.12, 0.22, 0.38, 0.35)
		if boss_statue:
			boss_statue.modulate = Color(0.5, 0.6, 0.75, 0.75)

func open_shrine_modal(shrine_id: String) -> void:
	if not SHRINES_DATA.has(shrine_id):
		return

	active_shrine_id = shrine_id
	current_shrine_q_idx = 0
	shrine_question_answered = false
	selected_option_idx = -1

	if player:
		player.can_move = false

	_render_current_shrine_question()
	shrine_modal.visible = true
	shrine_modal_card.scale = Vector2(0.92, 0.92)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(shrine_modal_card, "scale", Vector2.ONE, 0.22)

func _render_current_shrine_question() -> void:
	var data: Dictionary = SHRINES_DATA[active_shrine_id]
	var questions: Array = data.get("questions", [])
	var total_q: int = questions.size()
	var q_data: Dictionary = questions[current_shrine_q_idx]

	var is_bridge: bool = active_shrine_id.begins_with("bridge_")
	var cleared_list: Array = _get_unlocked_bridges() if is_bridge else _get_cleared_shrines()
	var already_cleared: bool = active_shrine_id in cleared_list

	shrine_question_answered = false
	selected_option_idx = -1

	var pips_str = ""
	for i in range(total_q):
		if i < current_shrine_q_idx:
			pips_str += "🟢 "
		elif i == current_shrine_q_idx:
			pips_str += "🟡 "
		else:
			pips_str += "⚪ "

	shrine_modal_icon.text = data["icon"]
	shrine_modal_title.text = data["title"]
	shrine_modal_topic.text = "Topic: %s   |   Step %d of %d  [%s]" % [data["topic"], current_shrine_q_idx + 1, total_q, pips_str.strip_edges()]
	shrine_lesson_text.text = data["lesson"]
	shrine_question_label.text = "[b]Trial Question (%d/%d):[/b] %s" % [current_shrine_q_idx + 1, total_q, q_data["question"]]

	for child in shrine_options_container.get_children():
		child.queue_free()

	var options: Array = q_data["options"]
	for i in range(options.size()):
		var btn = Button.new()
		btn.text = "  %s.  %s" % [["A", "B", "C", "D"][i], options[i]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 42)
		btn.focus_mode = Control.FOCUS_NONE
		_style_option_btn(btn, false, false, false)
		var idx = i
		btn.pressed.connect(func(): _on_select_shrine_option(idx))
		shrine_options_container.add_child(btn)

	if already_cleared:
		shrine_feedback_label.text = "✅ Already Attuned! Practicing Step %d/%d." % [current_shrine_q_idx + 1, total_q]
		shrine_feedback_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.55))
	else:
		shrine_feedback_label.text = "Select the correct Python statement to pass Step %d of %d." % [current_shrine_q_idx + 1, total_q]
		shrine_feedback_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.92))

	shrine_action_btn.text = "⚡ Submit Answer (%d/%d)" % [current_shrine_q_idx + 1, total_q]
	shrine_action_btn.disabled = true

func _style_option_btn(btn: Button, selected: bool, is_correct: bool, is_wrong: bool) -> void:
	var box = StyleBoxFlat.new()
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_left = 8
	box.corner_radius_bottom_right = 8
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = 2

	if is_correct:
		box.bg_color = Color(0.1, 0.35, 0.22, 0.95)
		box.border_color = Color(0.25, 0.95, 0.5, 1.0)
	elif is_wrong:
		box.bg_color = Color(0.38, 0.12, 0.15, 0.95)
		box.border_color = Color(0.95, 0.3, 0.35, 1.0)
	elif selected:
		box.bg_color = Color(0.16, 0.28, 0.48, 0.95)
		box.border_color = Color(0.35, 0.8, 1.0, 1.0)
	else:
		box.bg_color = Color(0.1, 0.14, 0.22, 0.9)
		box.border_color = Color(0.25, 0.32, 0.45, 0.8)

	btn.add_theme_stylebox_override("normal", box)
	btn.add_theme_stylebox_override("hover", box)
	btn.add_theme_stylebox_override("pressed", box)

func _on_select_shrine_option(idx: int) -> void:
	if shrine_question_answered:
		return
	selected_option_idx = idx
	shrine_action_btn.disabled = false

	var children = shrine_options_container.get_children()
	for i in range(children.size()):
		var btn = children[i] as Button
		_style_option_btn(btn, i == idx, false, false)

func _on_shrine_action() -> void:
	if shrine_question_answered:
		var data: Dictionary = SHRINES_DATA[active_shrine_id]
		var questions: Array = data.get("questions", [])
		if current_shrine_q_idx + 1 < questions.size():
			current_shrine_q_idx += 1
			_render_current_shrine_question()
		else:
			_on_close_shrine_modal()
		return

	if selected_option_idx < 0 or not SHRINES_DATA.has(active_shrine_id):
		return

	var data: Dictionary = SHRINES_DATA[active_shrine_id]
	var questions: Array = data.get("questions", [])
	var total_q: int = questions.size()
	var q_data: Dictionary = questions[current_shrine_q_idx]
	var correct_idx: int = q_data["correct_index"]
	var children = shrine_options_container.get_children()

	if selected_option_idx == correct_idx:
		shrine_question_answered = true
		_style_option_btn(children[selected_option_idx] as Button, true, true, false)

		if current_shrine_q_idx + 1 < total_q:
			shrine_feedback_label.text = "✅ Correct! %s" % q_data["explanation"]
			shrine_feedback_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
			shrine_action_btn.text = "Next Question (%d/%d) ➔" % [current_shrine_q_idx + 2, total_q]
		else:
			var is_bridge: bool = active_shrine_id.begins_with("bridge_")
			if is_bridge:
				var bridges = _get_unlocked_bridges()
				if not (active_shrine_id in bridges):
					bridges.append(active_shrine_id)
					SaveManager.user_profile["w2_bridges"] = bridges
					var reward_xp: int = data["xp"]
					SaveManager.user_profile["xp"] = int(SaveManager.user_profile.get("xp", 0)) + reward_xp
					SaveManager.save_local_profile()
					shrine_feedback_label.text = "🔓 Bridge Unsealed! (+%d XP) %s" % [reward_xp, q_data["explanation"]]
					show_toast("🌉 %s Unsealed! (+%d XP)" % [data["title"], reward_xp])
				else:
					shrine_feedback_label.text = "🔓 %s Verified! %s" % [data["title"], q_data["explanation"]]
				shrine_feedback_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
				shrine_action_btn.text = "Cross Bridge ✨"
				_refresh_bridge_states()
				_update_shrine_tracker(_get_cleared_shrines().size())
			else:
				var cleared = _get_cleared_shrines()
				if not (active_shrine_id in cleared):
					cleared.append(active_shrine_id)
					SaveManager.user_profile["w2_shrines"] = cleared
					var reward_xp: int = data["xp"]
					SaveManager.user_profile["xp"] = int(SaveManager.user_profile.get("xp", 0)) + reward_xp
					SaveManager.save_local_profile()
					shrine_feedback_label.text = "🎉 All %d Trials Passed! +%d XP Earned! %s" % [total_q, reward_xp, q_data["explanation"]]
					show_toast("✨ %s Awakened! (+%d XP)" % [data["title"], reward_xp])
				else:
					shrine_feedback_label.text = "🎉 All %d Trials Completed! %s" % [total_q, q_data["explanation"]]
				shrine_feedback_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
				shrine_action_btn.text = "Complete Trial ✨"
				_refresh_all_shrine_states()
	else:
		_style_option_btn(children[selected_option_idx] as Button, false, false, true)
		shrine_feedback_label.text = "❌ Not quite! Review the Control Structure Lesson above and try another option."
		shrine_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.45))

func _on_close_shrine_modal() -> void:
	shrine_modal.visible = false
	if player:
		player.can_move = true

# ---------------------------------------------------------
# Valley NPCs Dialog & Reward System
# ---------------------------------------------------------
func _get_helped_npcs() -> Array:
	var list = SaveManager.user_profile.get("w2_npcs_helped", [])
	if typeof(list) != TYPE_ARRAY:
		list = []
	return list

func _refresh_all_npc_states() -> void:
	var helped = _get_helped_npcs()
	var npcs_root = get_node_or_null("YSortEntities/NPCs")
	if not npcs_root:
		return
	for npc in npcs_root.get_children():
		if npc.has_method("set_rewarded") and "npc_id" in npc:
			npc.set_rewarded(npc.npc_id in helped)

func open_npc_dialog(npc_id: String) -> void:
	if not NPCS_DATA.has(npc_id):
		return
	active_dialog_mode = npc_id
	var data: Dictionary = NPCS_DATA[npc_id]
	var helped = _get_helped_npcs()
	var already_helped: bool = npc_id in helped

	if player:
		player.can_move = false

	var speaker_icon = get_node_or_null("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerIcon") as Label
	var speaker_name = get_node_or_null("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerName") as Label
	if speaker_icon:
		speaker_icon.text = data["icon"]
	if speaker_name:
		speaker_name.text = data["name"]

	quest_text.text = data["dialog"]
	decline_btn.text = "Close"

	if already_helped:
		accept_btn.text = "✅ Lesson Claimed"
		accept_btn.disabled = false
	else:
		accept_btn.text = "🎁 Claim +%d XP & +1 Hint" % data["xp"]
		accept_btn.disabled = false

	quest_dialog.visible = true

# ---------------------------------------------------------
# Treasure Chest Lore System
# ---------------------------------------------------------
func open_chest_lore(_chest_id: String, title: String, text: String, xp_reward: int, already_opened: bool) -> void:
	if player:
		player.can_move = false

	lore_title_label.text = "📦 Codex Scroll: %s" % title
	lore_text_label.text = text

	if already_opened:
		lore_xp_label.text = "✨ Already Recorded in Your Python Codex"
		lore_xp_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.95))
	else:
		SaveManager.user_profile["xp"] = int(SaveManager.user_profile.get("xp", 0)) + xp_reward
		SaveManager.save_local_profile()
		lore_xp_label.text = "🎉 +%d Bonus XP & +1 Hint Token!" % xp_reward
		lore_xp_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
		SaveManager.user_profile["hint_tokens"] = int(SaveManager.user_profile.get("hint_tokens", 5)) + 1
		SaveManager.save_local_profile()
		show_toast("📦 Discovered '%s'! (+%d XP)" % [title, xp_reward])

	lore_modal.visible = true
	lore_card.scale = Vector2(0.92, 0.92)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lore_card, "scale", Vector2.ONE, 0.22)

func _on_close_lore_modal() -> void:
	lore_modal.visible = false
	if player:
		player.can_move = true

# ---------------------------------------------------------
# Master PyWizard & Final Boss Gate
# ---------------------------------------------------------
func open_quest_dialog() -> void:
	active_dialog_mode = "boss"
	if player:
		player.can_move = false

	var speaker_icon = get_node_or_null("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerIcon") as Label
	var speaker_name = get_node_or_null("UILayer/QuestDialogModal/Center/DialogCard/DialogVBox/SpeakerHeader/SpeakerName") as Label
	if speaker_icon:
		speaker_icon.text = "🧙‍♂️"
	if speaker_name:
		speaker_name.text = "Master PyWizard • Guardian of the Final Seal"

	var cleared = _get_cleared_shrines()
	var count = cleared.size()

	if count >= 3:
		quest_text.text = "Magnificent work, Adventurer Alex! All 3 Control-Structure Shrines are awakened and the Chasm Bridges are unsealed!\n\nBeyond this Sanctuary waits CHRONOS-IF, THE INFINITE LOOP WARDEN (500 HP). Use your Python 'if / elif / else' conditions and 'for / while' loops to shatter his Temporal Armor!"
		accept_btn.text = "⚔️ Fight Boss: Chronos-If"
		accept_btn.disabled = false
		decline_btn.text = "Prepare More"
	else:
		var missing: PackedStringArray = []
		if not ("shrine_if_else" in cleared):
			missing.append("• Shrine of Branches (West Plaza — 4 Questions)")
		if not ("shrine_for_loops" in cleared):
			missing.append("• Shrine of Counting Loops (Southeast across South Bridge — 4 Questions)")
		if not ("shrine_while_loops" in cleared):
			missing.append("• Shrine of Sentinel Loops (Northeast across Chasm — 4 Questions)")

		quest_text.text = "Halt, young coder! The Boss Sanctuary of Chronos-If is sealed by 3 Ancient Logic Runes (%d/3 Awakened).\n\nUnseal the Chasm Bridges at their Terminals and awaken the remaining Shrines:\n%s" % [count, "\n".join(missing)]
		accept_btn.text = "🔒 Sealed (%d/3 Runes)" % count
		accept_btn.disabled = true
		decline_btn.text = "Explore Chamber"

	quest_dialog.visible = true

func _on_accept_quest() -> void:
	if active_dialog_mode != "boss":
		var npc_id = active_dialog_mode
		var helped = _get_helped_npcs()
		if not (npc_id in helped) and NPCS_DATA.has(npc_id):
			helped.append(npc_id)
			SaveManager.user_profile["w2_npcs_helped"] = helped
			var xp_gain: int = NPCS_DATA[npc_id]["xp"]
			SaveManager.user_profile["xp"] = int(SaveManager.user_profile.get("xp", 0)) + xp_gain
			SaveManager.user_profile["hint_tokens"] = int(SaveManager.user_profile.get("hint_tokens", 5)) + 1
			SaveManager.save_local_profile()
			_refresh_all_npc_states()
			show_toast("🎁 +%d XP & +1 Hint Token from %s!" % [xp_gain, NPCS_DATA[npc_id]["name"].split("•")[0].strip_edges()])
		_on_close_quest_dialog()
		return

	if _get_cleared_shrines().size() < 3:
		show_toast("🔒 Awaken all 3 Shrines first to unseal the Boss Battle!")
		return
	SaveManager.user_profile["current_level"] = 2
	SaveManager.save_local_profile()
	quest_dialog.visible = false
	SceneManager.change_scene(SceneManager.LEVEL_GAMEPLAY)

func _on_close_quest_dialog() -> void:
	quest_dialog.visible = false
	if player:
		player.can_move = true

func start_quiz(_json_path: String) -> void:
	open_quest_dialog()

func _on_back_to_select() -> void:
	SceneManager.change_scene(SceneManager.LEVEL_SELECT)

# ---------------------------------------------------------
# Toast Notification Helper
# ---------------------------------------------------------
func show_toast(message: String) -> void:
	if not toast_panel or not toast_label:
		return
	toast_label.text = message
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0

	if toast_tween and toast_tween.is_running():
		toast_tween.kill()

	toast_tween = create_tween()
	toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	toast_tween.tween_interval(3.0)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	toast_tween.tween_callback(func(): toast_panel.visible = false)

