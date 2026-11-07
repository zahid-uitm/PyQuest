# res://scripts/world/World3.gd
extends Node2D

@onready var player: CharacterBody2D = %Player
@onready var joystick: Control = %VirtualJoystick
@onready var quest_dialog: Control = %QuestDialogModal
@onready var quest_text: Label = %QuestText
@onready var accept_btn: Button = get_node_or_null("%AcceptButton")
@onready var decline_btn: Button = get_node_or_null("%DeclineButton")
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

# World Entities (Keep node names consistent with World1/World2 for scene validator)
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
var trap_state: int = 0 # 0 = IN SCOPE (Safe), 1 = CLOSING (Warning), 2 = OUT OF SCOPE (Surge)
var trap_cooldown: float = 0.0
var active_terminal_id: String = ""
var active_return_pad_id: String = ""
var warp_cooldown: float = 0.0
var player_at_boss_gate: bool = false

const RETURN_PADS_INFO: Dictionary = {
	"pad_center": {
		"name": "Central Rotunda Conduit",
		"pos": Vector2(1215, 650),
		"next_id": "pad_west"
	},
	"pad_west": {
		"name": "West Library Conduit",
		"pos": Vector2(440, 385),
		"next_id": "pad_east"
	},
	"pad_east": {
		"name": "East Forge Conduit",
		"pos": Vector2(1995, 985),
		"next_id": "pad_center"
	}
}

const NPCS_DATA: Dictionary = {
	"npc_archivist_def": {
		"name": "Grand Archivist Def • Keeper of Declarations",
		"icon": "📜",
		"portrait": "res://assets/sprites/portraits/portrait_npc_scholar.png",
		"xp": 50,
		"dialog": "Welcome to the Relic Vault, Adventurer Alex! This subterranean sanctuary was built using modular Python functions.\n\nTo define a reusable spell in Python, start with the 'def' keyword, followed by the function name, parentheses '()', and a colon ':':\n  def unseal_relic():\n      channel_mana()\n\nDefining a function stores the spell scroll—you must CALL it with 'unseal_relic()' to execute it! Take this Hint Token and XP!"
	},
	"npc_artificer_param": {
		"name": "Artificer Param • Master of Arguments",
		"icon": "⚙️",
		"portrait": "res://assets/sprites/portraits/portrait_npc_engineer.png",
		"xp": 50,
		"dialog": "Impressive—you invoked the West Seal Function with exact arguments! Welcome to the Western Archive Wing.\n\nParameters are variables listed inside a function's parentheses that receive input values (arguments) when called:\n  def forge_key(metal, runes=2):\n      print(metal, runes)\n\nNotice 'runes=2'? That's a Default Parameter—if you call 'forge_key(\"gold\")', 'runes' automatically defaults to 2! Take this Hint Token!"
	},
	"npc_oracle_ret": {
		"name": "Oracle Returnia • Weaver of Return & Scope",
		"icon": "🔮",
		"portrait": "res://assets/sprites/portraits/portrait_npc_scholar.png",
		"xp": 50,
		"dialog": "Greetings, modular mage! In the Eastern Forge Wing, our conduits run on Python's 'return' statement!\n\nA function that only uses 'print()' sends nothing back (it returns 'None'). To send a computed value back to the caller, use 'return':\n  def calc_power(base):\n      return base * 3\n\nYou can also step onto the glowing Return Conduit Pads and press [R] to teleport across the Vault! Take this Hint Token!"
	}
}

const SHRINES_DATA: Dictionary = {
	"shrine_def": {
		"title": "Shrine of Declarations",
		"icon": "📜",
		"color": Color(0.75, 0.45, 1.0),
		"topic": "Defining & Calling Functions (def)",
		"lesson": "[b]Python Functions ([code]def[/code]):[/b]\n• A function is a reusable named block of code that performs a specific task.\n• Use [code]def function_name():[/code] followed by an indented block to define a function.\n• Defining a function does NOT run it immediately—you must [b]call[/b] it with [code]function_name()[/code]!",
		"xp": 120,
		"questions": [
			{
				"question": "Which keyword is used to define a new function in Python?",
				"options": [
					"function",
					"def",
					"fun",
					"declare"
				],
				"correct_index": 1,
				"explanation": "In Python, 'def' (short for define) begins every function declaration!"
			},
			{
				"question": "What is the correct syntax to [b]call[/b] (execute) a function named [code]open_vault[/code]?",
				"options": [
					"def open_vault:",
					"call open_vault",
					"open_vault()",
					"open_vault[]"
				],
				"correct_index": 2,
				"explanation": "Adding parentheses 'open_vault()' calls and executes the function!"
			},
			{
				"question": "What will be printed when this code runs?\n[code]def cast_light():\n    print('Luminary!')\n\nprint('Entering Vault')[/code]",
				"options": [
					"Only 'Entering Vault' (because cast_light() was defined but never called)",
					"Both 'Luminary!' and 'Entering Vault'",
					"Only 'Luminary!'",
					"A SyntaxError"
				],
				"correct_index": 0,
				"explanation": "Defining 'cast_light()' only registers the function; since 'cast_light()' was never called, only 'Entering Vault' prints!"
			},
			{
				"question": "Why do programmers organize code into reusable functions?",
				"options": [
					"To avoid repeating code (DRY: Don't Repeat Yourself) and make programs modular",
					"Because Python does not allow code outside of functions",
					"To make variables disappear randomly",
					"To slow down program execution"
				],
				"correct_index": 0,
				"explanation": "Functions make code modular, readable, and reusable without copy-pasting the same lines!"
			}
		]
	},
	"shrine_params": {
		"title": "Shrine of Parameters",
		"icon": "⚙️",
		"color": Color(0.98, 0.78, 0.22),
		"topic": "Parameters, Arguments & Default Values",
		"lesson": "[b]Parameters & Arguments:[/b]\n• [b]Parameters[/b] are the placeholder names inside [code]def greet(hero, rank):[/code].\n• [b]Arguments[/b] are the actual values passed when calling [code]greet('Alex', 3)[/code].\n• A [b]Default Parameter[/b] like [code]def charge(mana, mult=2):[/code] uses [code]2[/code] if the second argument is omitted!",
		"xp": 120,
		"questions": [
			{
				"question": "What will this function call output?\n[code]def empower(gem, level):\n    print(gem, level * 10)\n\nempower('Amethyst', 4)[/code]",
				"options": [
					"Amethyst 40",
					"gem 40",
					"Amethyst 4",
					"level 10"
				],
				"correct_index": 0,
				"explanation": "'gem' receives 'Amethyst' and 'level' receives 4, so 'level * 10' evaluates to 40!"
			},
			{
				"question": "How many arguments are passed in the call [code]unlock_seal('west', 5, True)[/code]?",
				"options": [
					"1 argument",
					"2 arguments",
					"3 arguments",
					"0 arguments"
				],
				"correct_index": 2,
				"explanation": "There are 3 comma-separated arguments: 'west', 5, and True!"
			},
			{
				"question": "What is printed when a default parameter is used here?\n[code]def summon_shield(power=50):\n    print(power)\n\nsummon_shield()[/code]",
				"options": [
					"50",
					"0",
					"None",
					"TypeError"
				],
				"correct_index": 0,
				"explanation": "Since no argument was passed to 'summon_shield()', 'power' uses its default value of 50!"
			},
			{
				"question": "What happens if we call [code]summon_shield(120)[/code] on the function [code]def summon_shield(power=50):[/code]?",
				"options": [
					"'power' becomes 120, overriding the default value of 50",
					"'power' stays 50",
					"'power' becomes 170 (120 + 50)",
					"Python raises an error"
				],
				"correct_index": 0,
				"explanation": "Passing an explicit argument (120) overrides the default parameter value (50)!"
			}
		]
	},
	"shrine_return": {
		"title": "Shrine of Return Values",
		"icon": "🔮",
		"color": Color(0.25, 0.95, 0.72),
		"topic": "The return Statement & Variable Scope",
		"lesson": "[b]Return Values & Variable Scope:[/b]\n• [code]return value[/code] immediately exits the function and sends [code]value[/code] back to the caller.\n• You can store the returned value in a variable: [code]dmg = calc_hit(20)[/code].\n• Variables created inside a function have [b]Local Scope[/b] and cannot be accessed outside that function!",
		"xp": 120,
		"questions": [
			{
				"question": "What is the value of [code]result[/code] after running this code?\n[code]def double_mana(x):\n    return x * 2\n\nresult = double_mana(15) + 5[/code]",
				"options": [
					"35",
					"30",
					"20",
					"None"
				],
				"correct_index": 0,
				"explanation": "'double_mana(15)' returns 30, and '30 + 5' equals 35!"
			},
			{
				"question": "What happens to any lines of code written [b]after[/b] a [code]return[/code] statement inside the same function block?",
				"options": [
					"They are skipped because 'return' immediately exits the function",
					"They run before the return statement",
					"They run twice",
					"They delete the function"
				],
				"correct_index": 0,
				"explanation": "As soon as Python executes 'return', the function finishes and hands control back to the caller!"
			},
			{
				"question": "What does a Python function return if it has [b]no[/b] [code]return[/code] statement?",
				"options": [
					"None",
					"0",
					"False",
					"An empty string ''"
				],
				"correct_index": 0,
				"explanation": "In Python, any function that finishes without hitting a 'return' statement automatically returns 'None'!"
			},
			{
				"question": "Why does [code]print(secret_key)[/code] outside the function cause a [code]NameError[/code]?\n[code]def make_key():\n    secret_key = 99\n\nmake_key()\nprint(secret_key)[/code]",
				"options": [
					"Because 'secret_key' is a local variable that only exists inside 'make_key()'",
					"Because 99 is not a valid number",
					"Because 'make_key()' was not called",
					"Because 'print' cannot print integers"
				],
				"correct_index": 0,
				"explanation": "Variables assigned inside a function have Local Scope—they only exist while the function is running! Return the value to use it outside."
			}
		]
	},
	"seal_west": {
		"title": "West Archive Function Altar",
		"icon": "🔑",
		"color": Color(0.85, 0.55, 1.0),
		"topic": "Function Call & Argument Passing Protocol",
		"lesson": "[b]West Vault Seal Override:[/b] The Western Archive Wing is locked behind an Arcane Vault Seal! Invoke the reusable seal-breaker function with the exact arguments required to return [code]True[/code].",
		"xp": 75,
		"questions": [
			{
				"question": "[b]Step 1:[/b] Complete the function header so [code]break_seal[/code] accepts two parameters: [code]wing[/code] and [code]power[/code]:",
				"options": [
					"def break_seal(wing, power):",
					"function break_seal(wing, power):",
					"def break_seal[wing, power]:",
					"call break_seal(wing, power):"
				],
				"correct_index": 0,
				"explanation": "'def break_seal(wing, power):' defines a 2-parameter function in Python!"
			},
			{
				"question": "[b]Step 2:[/b] Given this function, which call returns [code]True[/code] to shatter the West Seal?\n[code]def break_seal(wing, power):\n    return wing == 'west' and power * 2 == 8[/code]",
				"options": [
					"break_seal('west', 4)",
					"break_seal('west', 8)",
					"break_seal('east', 4)",
					"break_seal(4, 'west')"
				],
				"correct_index": 0,
				"explanation": "Passing 'west' and 4 makes 'wing == \"west\"' True and '4 * 2 == 8' True! West Archive Wing unsealed!"
			}
		]
	},
	"seal_east": {
		"title": "East Forge Function Altar",
		"icon": "⚡",
		"color": Color(0.98, 0.8, 0.25),
		"topic": "Return Value & Default Parameter Protocol",
		"lesson": "[b]East Vault Seal Override:[/b] The Eastern Modularity Forge is sealed! Use a function with a [b]Default Parameter[/b] and [code]return[/code] statement to match the Forge's harmonic frequency of [code]10[/code].",
		"xp": 75,
		"questions": [
			{
				"question": "[b]Step 1:[/b] Which statement inside [code]unlock_forge[/code] sends the sum [code]key + boost[/code] back to the caller?\n[code]def unlock_forge(key, boost=3):\n    ____________[/code]",
				"options": [
					"return key + boost",
					"print(key + boost)",
					"def key + boost",
					"boost = key"
				],
				"correct_index": 0,
				"explanation": "'return key + boost' computes the sum and returns it to the Vault Seal mechanism!"
			},
			{
				"question": "[b]Step 2:[/b] Since [code]boost=3[/code] is a default parameter in [code]def unlock_forge(key, boost=3): return key + boost[/code], which single-argument call returns [code]10[/code]?",
				"options": [
					"unlock_forge(7)",
					"unlock_forge(10)",
					"unlock_forge(3)",
					"unlock_forge()"
				],
				"correct_index": 0,
				"explanation": "Calling 'unlock_forge(7)' sets key=7 and uses the default boost=3, returning 7 + 3 = 10! East Forge Wing unsealed!"
			}
		]
	}
}

func _ready() -> void:
	SaveManager.user_profile["current_level"] = 3
	if quest_dialog:
		quest_dialog.visible = false
	if shrine_modal:
		shrine_modal.visible = false
	if lore_modal:
		lore_modal.visible = false
	if toast_panel:
		toast_panel.visible = false
	if joystick:
		joystick.visible = bool(SaveManager.get_setting("show_joystick", true))

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
	if not accept_btn:
		accept_btn = find_child("AcceptButton", true, false) as Button
	if not decline_btn:
		decline_btn = find_child("DeclineButton", true, false) as Button

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

	# Connect World 3 Exclusive Mechanics: Function Seal Altars, Return Teleporter Pads & Scope Resonance Rings
	_setup_seal_altars()
	_setup_return_pads()
	_setup_scope_traps()

	var p_name = SaveManager.user_profile.get("full_name", "Adventurer Alex")
	if area_title_label:
		area_title_label.text = "🔮 The Relic Vault  |  %s" % p_name

	_refresh_all_shrine_states()
	_refresh_all_npc_states()
	_refresh_seal_states()

	AudioManager.play_bgm_by_path("res://assets/audio/world3_music.mp3")

func _process(delta: float) -> void:
	boss_anim_timer += delta
	if trap_cooldown > 0.0:
		trap_cooldown -= delta
	if warp_cooldown > 0.0:
		warp_cooldown -= delta

	var boss_statue = get_node_or_null("YSortEntities/TrialGate/BossStatue") as Sprite2D
	if boss_statue and boss_statue.hframes >= 6:
		boss_statue.frame = int(boss_anim_timer * 5.0) % 6

	# Cycle World 3 Scope Resonance Rings (0 = Local Scope SAFE [2.5s], 1 = Closing [1.0s], 2 = NameError Out-Of-Scope [1.7s])
	var cycle_pos = fmod(boss_anim_timer, 5.2)
	var new_state = 0
	if cycle_pos < 2.5:
		new_state = 0
	elif cycle_pos < 3.5:
		new_state = 1
	else:
		new_state = 2

	if new_state != trap_state:
		trap_state = new_state
		_update_trap_visuals()

	if trap_state == 2 and trap_cooldown <= 0.0:
		_check_player_in_armed_trap()

func _unhandled_input(event: InputEvent) -> void:
	if quest_dialog.visible or shrine_modal.visible or lore_modal.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and active_return_pad_id != "" and warp_cooldown <= 0.0:
			_trigger_return_pad_warp(active_return_pad_id)
		elif event.keycode == KEY_E or event.is_action_pressed("ui_accept"):
			if active_terminal_id != "":
				open_shrine_dialog(active_terminal_id)
			elif active_return_pad_id != "" and warp_cooldown <= 0.0:
				_trigger_return_pad_warp(active_return_pad_id)
			elif player_at_boss_gate:
				open_quest_dialog()

# ---------------------------------------------------------
# World 3 Exclusive #1: Arcane Function Seal Altars & Barriers
# ---------------------------------------------------------
func _get_unlocked_seals() -> Array:
	var list = SaveManager.user_profile.get("w3_seals", [])
	if typeof(list) != TYPE_ARRAY:
		list = []
	return list

func _setup_seal_altars() -> void:
	for s_id in ["seal_west", "seal_east"]:
		var node_name = "VaultSealWest" if s_id == "seal_west" else "VaultSealEast"
		var term_area = get_node_or_null("YSortEntities/" + node_name + "/TerminalArea") as Area2D
		if term_area:
			term_area.body_entered.connect(func(body: Node2D):
				if body.is_in_group("Player"):
					active_terminal_id = s_id
					var pr_in = term_area.get_node_or_null("PromptLabel") as Label
					if pr_in:
						pr_in.visible = true
			)
			term_area.body_exited.connect(func(body: Node2D):
				if body.is_in_group("Player"):
					if active_terminal_id == s_id:
						active_terminal_id = ""
					var pr_out = term_area.get_node_or_null("PromptLabel") as Label
					if pr_out:
						pr_out.visible = false
			)
			term_area.input_event.connect(func(_vp: Node, ev: InputEvent, _idx: int):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					if active_terminal_id == s_id:
						open_shrine_dialog(s_id)
			)

	var gate_area = get_node_or_null("YSortEntities/TrialGate/GateArea") as Area2D
	if gate_area:
		gate_area.body_entered.connect(func(body: Node2D):
			if body.is_in_group("Player"):
				player_at_boss_gate = true
				var pr_g_in = gate_area.get_node_or_null("PromptLabel") as Label
				if pr_g_in:
					pr_g_in.visible = true
		)
		gate_area.body_exited.connect(func(body: Node2D):
			if body.is_in_group("Player"):
				player_at_boss_gate = false
				var pr_g_out = gate_area.get_node_or_null("PromptLabel") as Label
				if pr_g_out:
					pr_g_out.visible = false
		)
		gate_area.input_event.connect(func(_vp: Node, ev: InputEvent, _idx: int):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				if player_at_boss_gate:
					open_quest_dialog()
		)

func _refresh_seal_states() -> void:
	var unlocked = _get_unlocked_seals()
	_apply_seal_visual("VaultSealWest", "seal_west" in unlocked, "West Archive Seal")
	_apply_seal_visual("VaultSealEast", "seal_east" in unlocked, "East Forge Seal")

func _apply_seal_visual(node_name: String, is_open: bool, label_title: String) -> void:
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
		term_spr.modulate = Color(0.45, 1.0, 0.78, 1.0) if is_open else Color(1.0, 0.85, 0.45, 1.0)
	if status_lbl:
		if is_open:
			status_lbl.text = "🔓 %s: UNSEALED (return True)" % label_title
			status_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.65))
		else:
			status_lbl.text = "🔒 %s: SEALED (Call Function)" % label_title
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))

# ---------------------------------------------------------
# World 3 Exclusive #2: Modular Return Teleporter Pads
# ---------------------------------------------------------
func _setup_return_pads() -> void:
	var pads_root = get_node_or_null("YSortEntities/ReturnPads")
	if not pads_root:
		return
	for pad in pads_root.get_children():
		if pad is Area2D:
			var pad_id: String = pad.get_meta("pad_id", "pad_center")
			pad.body_entered.connect(func(body: Node2D):
				if body.is_in_group("Player"):
					active_return_pad_id = pad_id
					var pr_pad_in = pad.get_node_or_null("PromptLabel") as Label
					if pr_pad_in:
						pr_pad_in.visible = true
			)
			pad.body_exited.connect(func(body: Node2D):
				if body.is_in_group("Player"):
					if active_return_pad_id == pad_id:
						active_return_pad_id = ""
					var pr_pad_out = pad.get_node_or_null("PromptLabel") as Label
					if pr_pad_out:
						pr_pad_out.visible = false
			)
			pad.input_event.connect(func(_vp: Node, ev: InputEvent, _idx: int):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					if active_return_pad_id == pad_id and warp_cooldown <= 0.0:
						_trigger_return_pad_warp(pad_id)
			)

func _trigger_return_pad_warp(from_pad_id: String) -> void:
	if not RETURN_PADS_INFO.has(from_pad_id) or not player:
		return
	var unlocked = _get_unlocked_seals()
	var target_id: String = RETURN_PADS_INFO[from_pad_id]["next_id"]

	# Ensure player has unsealed the target wing before warping into it!
	if target_id == "pad_west" and not ("seal_west" in unlocked):
		if "seal_east" in unlocked:
			target_id = "pad_east"
		else:
			show_toast("🔒 Unseal the West or East Function Altar first to activate the Return Conduit Network!")
			return
	elif target_id == "pad_east" and not ("seal_east" in unlocked):
		target_id = "pad_center"

	var dest_info: Dictionary = RETURN_PADS_INFO[target_id]
	var dest_pos: Vector2 = dest_info["pos"]
	warp_cooldown = 0.85
	AudioManager.play_teleport()

	player.modulate = Color(2.2, 1.8, 0.5, 1.0)
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(player, "scale", Vector2(0.3, 1.8), 0.14)
	tw.tween_callback(func():
		player.global_position = dest_pos
	)
	tw.tween_property(player, "scale", Vector2(1.0, 1.0), 0.18)
	tw.parallel().tween_property(player, "modulate", Color.WHITE, 0.25)

	show_toast("✨ return warp_to(\"%s\") ➔ (%d, %d)" % [dest_info["name"], int(dest_pos.x), int(dest_pos.y)])

# ---------------------------------------------------------
# World 3 Exclusive #3: Cycling Scope Resonance Rings
# ---------------------------------------------------------
func _setup_scope_traps() -> void:
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
				lbl.text = "🟣 in_scope == True (SAFE)"
				lbl.add_theme_color_override("font_color", Color(0.85, 0.68, 1.0))
			elif trap_state == 1:
				lbl.text = "🟡 Scope Closing: CAUTION"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
			else:
				lbl.text = "🔴 NameError: Out of Scope!"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.5))

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
		player.modulate = Color(2.2, 0.35, 0.85)
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(player, "global_position", target_pos, 0.2)
		tw.parallel().tween_property(player, "modulate", Color.WHITE, 0.35)
	show_toast("⚡ NameError: Variable Out of Scope! Cross when 'in_scope == True' (Violet)!")

# ---------------------------------------------------------
# Shrine System & Multi-Question Logic
# ---------------------------------------------------------
func _get_cleared_shrines() -> Array:
	var list = SaveManager.user_profile.get("w3_shrines", [])
	if typeof(list) != TYPE_ARRAY:
		list = []
	return list

func _refresh_all_shrine_states() -> void:
	var cleared = _get_cleared_shrines()

	if shrine_numbers and shrine_numbers.has_method("set_activated"):
		shrine_numbers.set_activated("shrine_def" in cleared)
	if shrine_strings and shrine_strings.has_method("set_activated"):
		shrine_strings.set_activated("shrine_params" in cleared)
	if shrine_booleans and shrine_booleans.has_method("set_activated"):
		shrine_booleans.set_activated("shrine_return" in cleared)

	_update_shrine_tracker(cleared.size())
	_update_gate_visuals(cleared)

func _update_shrine_tracker(count: int) -> void:
	if not shrine_tracker_label:
		return
	var cleared = _get_cleared_shrines()
	var seals = _get_unlocked_seals()
	var icon1 = "📜" if "shrine_def" in cleared else "⚪"
	var icon2 = "⚙️" if "shrine_params" in cleared else "⚪"
	var icon3 = "🔮" if "shrine_return" in cleared else "⚪"
	if count >= 3:
		shrine_tracker_label.text = "✨ All 3 Shrines Awakened! [%s %s %s] ➔ Challenge Boss Lambda-Prime!" % [icon1, icon2, icon3]
		shrine_tracker_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.65))
	else:
		shrine_tracker_label.text = "Shrines: %d/3 [%s %s %s]  |  Vault Seals Broken: %d/2" % [count, icon1, icon2, icon3, seals.size()]
		shrine_tracker_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))

func _update_gate_visuals(cleared: Array) -> void:
	if gate_rune_1:
		gate_rune_1.modulate = Color(0.8, 0.45, 1.0, 1.0) if "shrine_def" in cleared else Color(0.25, 0.3, 0.4, 0.5)
	if gate_rune_2:
		gate_rune_2.modulate = Color(0.98, 0.8, 0.25, 1.0) if "shrine_params" in cleared else Color(0.25, 0.3, 0.4, 0.5)
	if gate_rune_3:
		gate_rune_3.modulate = Color(0.3, 0.95, 0.72, 1.0) if "shrine_return" in cleared else Color(0.25, 0.3, 0.4, 0.5)
	if gate_particles:
		gate_particles.emitting = (cleared.size() >= 3)

	var gate_banner = get_node_or_null("YSortEntities/TrialGate/GateBanner") as Label
	var portal_aura = get_node_or_null("YSortEntities/TrialGate/PortalAura") as Polygon2D
	var boss_statue = get_node_or_null("YSortEntities/TrialGate/BossStatue") as Sprite2D
	if cleared.size() >= 3:
		if gate_banner:
			gate_banner.text = "⚔️ BOSS UNSEALED: Lambda-Prime, The Relic Sovereign"
			gate_banner.add_theme_color_override("font_color", Color(0.35, 1.0, 0.65))
		if portal_aura:
			portal_aura.color = Color(0.65, 0.3, 1.0, 0.65)
		if boss_statue:
			boss_statue.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		if gate_banner:
			gate_banner.text = "🔒 FINAL BOSS SANCTUM: Sealed (%d/3 Runes)" % cleared.size()
			gate_banner.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
		if portal_aura:
			portal_aura.color = Color(0.25, 0.14, 0.38, 0.35)
		if boss_statue:
			boss_statue.modulate = Color(0.6, 0.5, 0.75, 0.75)

func open_shrine_dialog(shrine_id: String) -> void:
	open_shrine_modal(shrine_id)

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

	var is_seal: bool = active_shrine_id.begins_with("seal_")
	var cleared_list: Array = _get_unlocked_seals() if is_seal else _get_cleared_shrines()
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
		shrine_feedback_label.text = "Select the correct Python function syntax to pass Step %d of %d." % [current_shrine_q_idx + 1, total_q]
		shrine_feedback_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.95))

	shrine_action_btn.text = "⚡ Invoke Function (%d/%d)" % [current_shrine_q_idx + 1, total_q]
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
		box.bg_color = Color(0.24, 0.16, 0.45, 0.95)
		box.border_color = Color(0.95, 0.78, 0.25, 1.0)
	else:
		box.bg_color = Color(0.14, 0.1, 0.24, 0.9)
		box.border_color = Color(0.38, 0.26, 0.58, 0.8)

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
	if not SHRINES_DATA.has(active_shrine_id):
		return

	var data: Dictionary = SHRINES_DATA[active_shrine_id]
	var questions: Array = data.get("questions", [])
	var total_q: int = questions.size()

	if shrine_question_answered:
		if current_shrine_q_idx + 1 < total_q:
			current_shrine_q_idx += 1
			_render_current_shrine_question()
		else:
			_on_close_shrine_modal()
		return

	if selected_option_idx < 0:
		return

	var q_data: Dictionary = questions[current_shrine_q_idx]
	var correct_idx: int = q_data["correct_index"]
	var children = shrine_options_container.get_children()

	if selected_option_idx == correct_idx:
		shrine_question_answered = true
		_style_option_btn(children[selected_option_idx] as Button, true, true, false)

		if current_shrine_q_idx + 1 < total_q:
			AudioManager.play_sfx()
			shrine_feedback_label.text = "✅ Correct! %s" % q_data["explanation"]
			shrine_feedback_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
			shrine_action_btn.text = "Next Question (%d/%d) ➔" % [current_shrine_q_idx + 2, total_q]
		else:
			var reward_xp: int = data.get("xp", 100)
			var is_seal: bool = active_shrine_id.begins_with("seal_")
			if is_seal:
				AudioManager.play_bridge_extend()
				var seals = _get_unlocked_seals()
				if not (active_shrine_id in seals):
					seals.append(active_shrine_id)
					SaveManager.user_profile["w3_seals"] = seals
					SaveManager.user_profile["xp"] = int(SaveManager.user_profile.get("xp", 0)) + reward_xp
					SaveManager.save_local_profile()
					BadgeManager.check_all_badges()
					shrine_feedback_label.text = "🔓 Vault Seal Broken! (+%d XP) %s" % [reward_xp, q_data["explanation"]]
					show_toast("🔑 %s Unsealed! (+%d XP)" % [data["title"], reward_xp])
				else:
					shrine_feedback_label.text = "🔓 %s Verified! %s" % [data["title"], q_data["explanation"]]
				shrine_feedback_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
				shrine_action_btn.text = "Enter Vault Wing ✨"
				_refresh_seal_states()
				_update_shrine_tracker(_get_cleared_shrines().size())
			else:
				AudioManager.play_shrine_awaken()
				var cleared = _get_cleared_shrines()
				if not (active_shrine_id in cleared):
					cleared.append(active_shrine_id)
					SaveManager.user_profile["w3_shrines"] = cleared
					SaveManager.user_profile["xp"] = int(SaveManager.user_profile.get("xp", 0)) + reward_xp
					SaveManager.save_local_profile()
					BadgeManager.check_all_badges()
					shrine_feedback_label.text = "🎉 All %d Trials Passed! +%d XP Earned! %s" % [total_q, reward_xp, q_data["explanation"]]
					show_toast("✨ %s Awakened! (+%d XP)" % [data["title"], reward_xp])
				else:
					shrine_feedback_label.text = "🎉 All %d Trials Completed! %s" % [total_q, q_data["explanation"]]
				shrine_feedback_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
				shrine_action_btn.text = "Complete Trial ✨"
				_refresh_all_shrine_states()
	else:
		AudioManager.play_error()
		_style_option_btn(children[selected_option_idx] as Button, false, false, true)
		shrine_feedback_label.text = "❌ Not quite! Review the Function & Modularity Lesson above and try another option."
		shrine_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.45))

func _on_close_shrine_modal() -> void:
	shrine_modal.visible = false
	if player:
		player.can_move = true

# ---------------------------------------------------------
# Vault NPCs Dialog & Reward System
# ---------------------------------------------------------
func _get_helped_npcs() -> Array:
	var list = SaveManager.user_profile.get("w3_npcs_helped", [])
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

func _update_dialog_speaker(icon_str: String, name_str: String, portrait_path: String) -> void:
	if not quest_dialog:
		return
	var s_icon = quest_dialog.find_child("SpeakerIcon", true, false) as Label
	var s_name = quest_dialog.find_child("SpeakerName", true, false) as Label
	var s_port = quest_dialog.find_child("SpeakerPortrait", true, false) as TextureRect
	if s_icon:
		s_icon.text = icon_str
	if s_name:
		s_name.text = name_str
	if s_port and ResourceLoader.exists(portrait_path):
		s_port.texture = load(portrait_path)
		s_port.pivot_offset = Vector2(52, 52)
		s_port.scale = Vector2(0.88, 0.88)
		var p_tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		p_tw.tween_property(s_port, "scale", Vector2.ONE, 0.25)

func open_npc_dialog(npc_id: String) -> void:
	if not NPCS_DATA.has(npc_id):
		return
	active_dialog_mode = npc_id
	var data: Dictionary = NPCS_DATA[npc_id]
	var helped = _get_helped_npcs()
	var already_helped: bool = npc_id in helped

	if player:
		player.can_move = false

	_update_dialog_speaker(data["icon"], data["name"], data.get("portrait", "res://assets/sprites/portraits/portrait_npc_scholar.png"))

	if not accept_btn:
		accept_btn = find_child("AcceptButton", true, false) as Button
	if not decline_btn:
		decline_btn = find_child("DeclineButton", true, false) as Button

	if quest_text:
		quest_text.text = data["dialog"]
	if decline_btn:
		decline_btn.text = "Close"

	if already_helped:
		if accept_btn:
			accept_btn.text = "✅ Lesson Claimed"
			accept_btn.disabled = false
	else:
		if accept_btn:
			accept_btn.text = "🎁 Claim +%d XP & +1 Hint" % data["xp"]
			accept_btn.disabled = false

	quest_dialog.visible = true
	AudioManager.play_npc_chat()

# ---------------------------------------------------------
# Treasure Chest Lore System
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
		lore_card.scale = Vector2(0.92, 0.92)
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(lore_card, "scale", Vector2.ONE, 0.22)

	show_toast("📦 Found Relic Scroll: %s (+%d XP!)" % [title, xp])

func _on_close_lore_modal() -> void:
	if lore_modal:
		lore_modal.visible = false
	if player:
		player.can_move = true
	if joystick:
		joystick.visible = true

# ---------------------------------------------------------
# Master PyWizard & Final Boss Gate
# ---------------------------------------------------------
func open_quest_dialog() -> void:
	active_dialog_mode = "boss"
	if player:
		player.can_move = false

	var cleared = _get_cleared_shrines()
	var count = cleared.size()

	if not accept_btn:
		accept_btn = find_child("AcceptButton", true, false) as Button
	if not decline_btn:
		decline_btn = find_child("DeclineButton", true, false) as Button

	if count >= 3:
		_update_dialog_speaker("👑", "Lambda-Prime • The Modular Relic Sovereign", "res://assets/sprites/portraits/portrait_lambda.png")
		if quest_text:
			quest_text.text = "Magnificent modularity, Adventurer Alex! All 3 Function Shrines are awakened and both Vault Wing Seals are broken!\n\nBeyond this Sanctum waits LAMBDA-PRIME, THE MODULAR RELIC SOVEREIGN (500 HP). Use your Python 'def' declarations, parameters, default arguments, and 'return' values to shatter his Arcane Relic Armor!"
		if accept_btn:
			accept_btn.text = "⚔️ Fight Boss: Lambda-Prime"
			accept_btn.disabled = false
		if decline_btn:
			decline_btn.text = "Prepare More"
	else:
		_update_dialog_speaker("🧙‍♂️", "Master PyWizard • Guardian of the Relic Sanctum", "res://assets/sprites/portraits/portrait_pywizard.png")
		var missing: PackedStringArray = []
		if not ("shrine_def" in cleared):
			missing.append("• Shrine of Declarations (Southwest Alcove — 4 Questions)")
		if not ("shrine_params" in cleared):
			missing.append("• Shrine of Parameters (West Library Wing via West Function Altar — 4 Questions)")
		if not ("shrine_return" in cleared):
			missing.append("• Shrine of Return Values (East Forge Wing via East Function Altar — 4 Questions)")

		if quest_text:
			quest_text.text = "Halt, young coder! The Sanctum of Lambda-Prime is sealed by 3 Ancient Function Runes (%d/3 Awakened).\n\nInvoke the West & East Function Seal Altars and awaken the remaining Shrines:\n%s" % [count, "\n".join(missing)]
		if accept_btn:
			accept_btn.text = "🔒 Sealed (%d/3 Runes)" % count
			accept_btn.disabled = true
		if decline_btn:
			decline_btn.text = "Explore Relic Vault"

	quest_dialog.visible = true
	AudioManager.play_npc_chat()

func _on_accept_quest() -> void:
	if active_dialog_mode != "boss":
		var npc_id = active_dialog_mode
		var helped = _get_helped_npcs()
		if not (npc_id in helped) and NPCS_DATA.has(npc_id):
			helped.append(npc_id)
			SaveManager.user_profile["w3_npcs_helped"] = helped
			var xp_gain: int = NPCS_DATA[npc_id]["xp"]
			SaveManager.user_profile["xp"] = int(SaveManager.user_profile.get("xp", 0)) + xp_gain
			SaveManager.user_profile["hint_tokens"] = int(SaveManager.user_profile.get("hint_tokens", 5)) + 1
			SaveManager.save_local_profile()
			BadgeManager.check_all_badges()
			_refresh_all_npc_states()
			show_toast("🎁 +%d XP & +1 Hint Token from %s!" % [xp_gain, NPCS_DATA[npc_id]["name"].split("•")[0].strip_edges()])
		_on_close_quest_dialog()
		return

	if _get_cleared_shrines().size() < 3:
		show_toast("🔒 Awaken all 3 Shrines first to unseal the Boss Battle!")
		return
	SaveManager.user_profile["current_level"] = 3
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

