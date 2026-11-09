# res://scripts/world/World4.gd
extends Node2D

@onready var player: CharacterBody2D = %Player
@onready var joystick: Control = %VirtualJoystick
@onready var quest_dialog: Control = %QuestDialogModal
@onready var quest_text: Label = %QuestText
@onready var accept_btn: Button = get_node_or_null("%AcceptButton")
@onready var decline_btn: Button = get_node_or_null("%DeclineButton")
@onready var hud_back_btn: Button = %BackToSelectButton
@onready var pause_modal: ColorRect = get_node_or_null("%PauseModal")
@onready var area_title_label: Label = %AreaTitleLabel

var spawn_position: Vector2 = Vector2.ZERO

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
var trap_state: int = 0 # 0 = VALID INDEX (Safe), 1 = BOUNDARY (Warning), 2 = IndexError (Spikes!)
var trap_cooldown: float = 0.0
var active_terminal_id: String = ""
var active_relic_id: String = ""
var player_at_boss_gate: bool = false
var bottom_dialog_bar: CanvasLayer = null

const RELICS_INFO: Dictionary = {
	"skull_key": {
		"name": "skull_key",
		"label": "🗝️ 'skull_key' (Index [0])",
		"xp": 40
	},
	"jade_urn": {
		"name": "jade_urn",
		"label": "🏺 'jade_urn' (Index [1])",
		"xp": 40
	},
	"soul_gem": {
		"name": "soul_gem",
		"label": "💎 'soul_gem' (Index [2])",
		"xp": 40
	}
}

const NPCS_DATA: Dictionary = {
	"npc_curator_idx": {
		"name": "Tomb Curator Indexa • Keeper of Zero-Based Indexing",
		"icon": "🗝️",
		"portrait": "res://assets/sprites/portraits/portrait_npc_scholar.png",
		"xp": 50,
		"dialog": "Tread carefully on the numbered crypt tiles, Adventurer Alex! Welcome to The Catacombs!\n\nIn Python, a List stores an ordered sequence of items inside square brackets '[]', and indexing ALWAYS starts at 0:\n  relics = ['skull_key', 'jade_urn', 'soul_gem']\n  first = relics[0]   # 'skull_key'\n  last  = relics[-1]  # 'soul_gem'\n\nTry picking up the glowing Crypt Relics around the Catacombs to '.append()' them to your live inventory list! Take this Hint Token and XP!"
	},
	"npc_warden_mut": {
		"name": "Ossuary Warden Appendo • Master of List Mutation",
		"icon": "🏺",
		"portrait": "res://assets/sprites/portraits/portrait_npc_engineer.png",
		"xp": 50,
		"dialog": "Well done unlocking the West Ossuary Portcullis, Alex! Unlike strings, Python Lists are MUTABLE—you can change, add, or remove items at any time!\n\n• 'bag.append(item)' adds an item to the END of the list.\n• 'bag.pop()' removes and returns the LAST item.\n• 'bag[0] = \"new_item\"' replaces the item at index 0!\n\nWatch out for red 'IndexError' floor tiles when exploring! Take this Hint Token!"
	},
	"npc_seers_seq": {
		"name": "Crypt Seer Slicia • Weaver of Slices & Search",
		"icon": "🔮",
		"portrait": "res://assets/sprites/portraits/portrait_npc_scholar.png",
		"xp": 50,
		"dialog": "Greetings, seeker of sequences! In the Eastern Crypt Wing, we master 'len()', membership search 'in', and List Slicing!\n\n• 'len(urns)' counts how many elements are in the list.\n• '\"key\" in urns' returns True if 'key' is inside the list.\n• 'urns[1:3]' slices elements from index 1 up to (but NOT including) index 3!\n\nTake this Hint Token for your final battle against Vektor-Zero!"
	}
}

const SHRINES_DATA: Dictionary = {
	"shrine_indexing": {
		"title": "Shrine of Indexing",
		"icon": "🗝️",
		"color": Color(0.2, 0.92, 0.65),
		"topic": "Creating Lists, Zero-Based & Negative Indexing",
		"lesson": "[b]Python Lists & Indexing:[/b]\n• Lists hold ordered sequences inside square brackets: [code]keys = ['gold', 'silver', 'iron'][/code].\n• [b]Zero-Based Indexing:[/b] [code]keys[0][/code] is the first item ([code]'gold'[/code]), [code]keys[1][/code] is the second ([code]'silver'[/code]).\n• [b]Negative Indexing:[/b] [code]keys[-1][/code] accesses the LAST item ([code]'iron'[/code])!",
		"xp": 120,
		"questions": [
			{
				"question": "What value is accessed by [code]urns[0][/code] in this Python list?\n[code]urns = ['amber', 'emerald', 'obsidian'][/code]",
				"options": [
					"'amber' (the first item)",
					"'emerald' (the second item)",
					"'obsidian' (the last item)",
					"0"
				],
				"correct_index": 0,
				"explanation": "Python lists are 0-indexed! Index 0 always points to the very first element ('amber')."
			},
			{
				"question": "In the list [code]gems = [10, 20, 30, 40][/code], which expression accesses the value [code]30[/code]?",
				"options": [
					"gems[3]",
					"gems[2]",
					"gems[1]",
					"gems(30)"
				],
				"correct_index": 1,
				"explanation": "Counting from 0: index 0 is 10, index 1 is 20, and index 2 is 30!"
			},
			{
				"question": "What does negative index [code]scrolls[-1][/code] return?\n[code]scrolls = ['alpha', 'beta', 'omega'][/code]",
				"options": [
					"'omega' (the last element in the list)",
					"'alpha' (the first element)",
					"An IndexError",
					"-1"
				],
				"correct_index": 0,
				"explanation": "Index -1 always refers to the last element of a non-empty Python list!"
			},
			{
				"question": "What happens if you try to access [code]items[3][/code] when [code]items = ['sword', 'shield', 'potion'][/code]?",
				"options": [
					"Python raises an IndexError: list index out of range (valid indices are 0, 1, 2)",
					"It returns 'potion'",
					"It returns None",
					"It automatically creates a 4th item"
				],
				"correct_index": 0,
				"explanation": "A 3-item list only has indices 0, 1, and 2—accessing index 3 triggers an IndexError!"
			}
		]
	},
	"shrine_mutation": {
		"title": "Shrine of Mutation",
		"icon": "🏺",
		"color": Color(0.96, 0.72, 0.22),
		"topic": "List Methods: .append(), .pop(), and Item Assignment",
		"lesson": "[b]Mutating Lists:[/b]\n• [code]list.append(x)[/code] adds [code]x[/code] to the [b]end[/b] of the list.\n• [code]list.pop()[/code] removes and returns the [b]last[/b] item (or at a given index [code]list.pop(0)[/code]).\n• [code]list[1] = 'new'[/code] overwrites the element at index [code]1[/code]!",
		"xp": 120,
		"questions": [
			{
				"question": "What does [code]bag[/code] contain after running this code?\n[code]bag = ['torch', 'rope']\nbag.append('key')[/code]",
				"options": [
					"['torch', 'rope', 'key']",
					"['key', 'torch', 'rope']",
					"['torch', 'key']",
					"['key']"
				],
				"correct_index": 0,
				"explanation": "'.append('key')' adds 'key' directly to the end of the 'bag' list!"
			},
			{
				"question": "What will [code]runes[/code] look like after modifying index 1?\n[code]runes = ['fire', 'ice', 'wind']\nrunes[1] = 'lightning'[/code]",
				"options": [
					"['fire', 'lightning', 'wind']",
					"['lightning', 'ice', 'wind']",
					"['fire', 'ice', 'lightning']",
					"['fire', 'lightning', 'ice', 'wind']"
				],
				"correct_index": 0,
				"explanation": "Index 1 is the second element ('ice'), so 'runes[1] = \"lightning\"' replaces 'ice' with 'lightning'!"
			},
			{
				"question": "Which list method removes and returns the [b]last[/b] element of a list [code]stack[/code]?",
				"options": [
					"stack.pop()",
					"stack.append()",
					"stack.first()",
					"stack.count()"
				],
				"correct_index": 0,
				"explanation": "'stack.pop()' pops the last item off the end of the list and returns it!"
			},
			{
				"question": "Which statement inserts [code]'crown'[/code] at the very beginning (index [code]0[/code]) of [code]loot[/code] without deleting anything?",
				"options": [
					"loot.insert(0, 'crown')",
					"loot.append('crown')",
					"loot[0] = 'crown'",
					"loot.pop(0)"
				],
				"correct_index": 0,
				"explanation": "'loot.insert(0, \"crown\")' inserts 'crown' at index 0 and shifts existing elements to the right!"
			}
		]
	},
	"shrine_sequences": {
		"title": "Shrine of Sequences",
		"icon": "🔮",
		"color": Color(0.35, 0.95, 0.78),
		"topic": "len(), Slicing [start:stop], and 'in' Search",
		"lesson": "[b]Sequence Operations:[/b]\n• [code]len(my_list)[/code] returns the total number of elements.\n• [code]item in my_list[/code] returns [code]True[/code] if [code]item[/code] is found inside the list.\n• [code]my_list[1:3][/code] slices elements starting at index [code]1[/code] up to (but [b]excluding[/b]) index [code]3[/code]!",
		"xp": 120,
		"questions": [
			{
				"question": "What does [code]len(crypt_keys)[/code] return?\n[code]crypt_keys = [101, 202, 303, 404, 505][/code]",
				"options": [
					"5",
					"4",
					"505",
					"101"
				],
				"correct_index": 0,
				"explanation": "'len()' counts the total number of elements in the list—there are 5 numbers!"
			},
			{
				"question": "What boolean value does this expression evaluate to?\n[code]relics = ['skull', 'urn', 'gem']\nprint('urn' in relics)[/code]",
				"options": [
					"True",
					"False",
					"1",
					"'urn'"
				],
				"correct_index": 0,
				"explanation": "The 'in' operator searches the list and returns True because 'urn' is an element of 'relics'!"
			},
			{
				"question": "What sublist is returned by the slice [code]nums[1:3][/code]?\n[code]nums = [10, 20, 30, 40][/code]",
				"options": [
					"[20, 30]",
					"[10, 20, 30]",
					"[20, 30, 40]",
					"[10, 20]"
				],
				"correct_index": 0,
				"explanation": "Slice 'nums[1:3]' starts at index 1 (20) and stops BEFORE index 3, giving [20, 30]!"
			},
			{
				"question": "What is the value of [code]total[/code] after looping over this list?\n[code]coins = [5, 10, 15]\ntotal = 0\nfor c in coins:\n    total = total + c[/code]",
				"options": [
					"30",
					"15",
					"3",
					"5"
				],
				"correct_index": 0,
				"explanation": "The loop visits each element (5, 10, 15) and adds them together: 5 + 10 + 15 = 30!"
			}
		]
	},
	"gate_west": {
		"title": "West Ossuary Matrix Pedestal",
		"icon": "🏺",
		"color": Color(0.95, 0.72, 0.25),
		"topic": "List Indexing & .append() Gate Protocol",
		"lesson": "[b]West Portcullis Override:[/b] The Western Ossuary Wing is blocked by an Iron-Emerald Portcullis! Solve a 2-step Python List Indexing & Mutation check to raise the gate.",
		"xp": 75,
		"questions": [
			{
				"question": "[b]Step 1:[/b] Given [code]seals = ['emerald', 'amber', 'bone'][/code], which expression selects [code]'emerald'[/code]?",
				"options": [
					"seals[0]",
					"seals[1]",
					"seals[-1]",
					"seals('emerald')"
				],
				"correct_index": 0,
				"explanation": "'seals[0]' selects the first element ('emerald') using zero-based indexing!"
			},
			{
				"question": "[b]Step 2:[/b] Which statement appends the [code]'master_key'[/code] string to the end of the [code]seals[/code] list to raise the West Portcullis?",
				"options": [
					"seals.append('master_key')",
					"seals.add('master_key')",
					"seals.pop('master_key')",
					"seals[0] = 'master_key'"
				],
				"correct_index": 0,
				"explanation": "'seals.append(\"master_key\")' adds the key to the end of the list! West Ossuary Portcullis raised!"
			}
		]
	},
	"gate_east": {
		"title": "East Sequence Matrix Pedestal",
		"icon": "🔮",
		"color": Color(0.25, 0.95, 0.72),
		"topic": "len() & 'in' Membership Gate Protocol",
		"lesson": "[b]East Portcullis Override:[/b] The Eastern Sequence Crypt requires verifying list length with [code]len()[/code] and searching for the cipher key with [code]in[/code]!",
		"xp": 75,
		"questions": [
			{
				"question": "[b]Step 1:[/b] Which condition checks if [code]'cipher'[/code] exists inside the list [code]tablets[/code]?",
				"options": [
					"if 'cipher' in tablets:",
					"if tablets.has('cipher'):",
					"if 'cipher' == tablets:",
					"for 'cipher' in tablets:"
				],
				"correct_index": 0,
				"explanation": "'if \"cipher\" in tablets:' uses Python's 'in' operator to search the list!"
			},
			{
				"question": "[b]Step 2:[/b] Which expression checks that the [code]tablets[/code] list contains [b]exactly 3[/b] elements?",
				"options": [
					"if len(tablets) == 3:",
					"if tablets.size == 3:",
					"if tablets[3] == True:",
					"if count(tablets) == 3:"
				],
				"correct_index": 0,
				"explanation": "'len(tablets) == 3' verifies the list has 3 elements! East Sequence Portcullis raised!"
			}
		]
	}
}

func _ready() -> void:
	SaveManager.user_profile["current_level"] = 4
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
	if player:
		spawn_position = player.global_position

	if not pause_modal:
		var pm_scene = load("res://scenes/ui/PauseModal.tscn")
		if pm_scene:
			pause_modal = pm_scene.instantiate()
			$UILayer.add_child(pause_modal)

	if hud_back_btn and not hud_back_btn.pressed.is_connected(_on_pause_pressed):
		hud_back_btn.pressed.connect(_on_pause_pressed)
	if pause_modal:
		if not pause_modal.resumed.is_connected(_on_pause_resumed):
			pause_modal.resumed.connect(_on_pause_resumed)
		if not pause_modal.respawn_requested.is_connected(_on_pause_respawn):
			pause_modal.respawn_requested.connect(_on_pause_respawn)

	if shrine_close_btn and not shrine_close_btn.pressed.is_connected(_on_close_shrine_modal):
		shrine_close_btn.pressed.connect(_on_close_shrine_modal)
	if shrine_action_btn and not shrine_action_btn.pressed.is_connected(_on_shrine_action):
		shrine_action_btn.pressed.connect(_on_shrine_action)

	if lore_close_btn and not lore_close_btn.pressed.is_connected(_on_close_lore_modal):
		lore_close_btn.pressed.connect(_on_close_lore_modal)

	# Connect World 4 Exclusive Mechanics: Matrix Gate Pedestals, Collectible List Relics & IndexError Traps
	_setup_matrix_gates()
	_setup_collectible_relics()
	_setup_index_traps()

	var p_name = SaveManager.user_profile.get("full_name", "Adventurer Alex")
	if area_title_label:
		area_title_label.text = "🏺 The Catacombs  |  %s" % p_name

	_refresh_all_shrine_states()
	_refresh_all_npc_states()
	_refresh_gate_states()
	_refresh_relic_nodes()

	AudioManager.play_bgm_by_path("res://assets/audio/world4_music.mp3")

	var bdb_scene = load("res://scenes/ui/BottomDialogBar.tscn")
	if bdb_scene:
		bottom_dialog_bar = bdb_scene.instantiate()
		add_child(bottom_dialog_bar)
		bottom_dialog_bar.dialog_finished.connect(func():
			if player and (not quest_dialog or not quest_dialog.visible) and (not shrine_modal or not shrine_modal.visible):
				player.can_move = true
		)
		if SaveManager.should_play_world_intro(4):
			if player:
				player.can_move = false
			bottom_dialog_bar.play_world_intro(4)

func _process(delta: float) -> void:
	boss_anim_timer += delta
	if trap_cooldown > 0.0:
		trap_cooldown -= delta

	var boss_statue = get_node_or_null("YSortEntities/TrialGate/BossStatue") as Sprite2D
	if boss_statue and boss_statue.hframes >= 6:
		boss_statue.frame = int(boss_anim_timer * 5.0) % 6

	# Bob collectible relics gently
	var relics_root = get_node_or_null("YSortEntities/CryptRelics")
	if relics_root:
		for r in relics_root.get_children():
			var spr = r.get_node_or_null("RelicSprite") as Sprite2D
			if spr:
				spr.position.y = -12.0 + sin(boss_anim_timer * 3.8 + r.position.x * 0.02) * 4.5

	# Cycle World 4 IndexError Crypt Spike Tiles (0 = Valid Index [2.5s], 1 = Boundary [1.0s], 2 = IndexError [1.7s])
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
	if event.is_action_pressed("ui_cancel"):
		if quest_dialog and quest_dialog.visible:
			_on_close_quest_dialog()
			get_viewport().set_input_as_handled()
		elif shrine_modal and shrine_modal.visible:
			_on_close_shrine_modal()
			get_viewport().set_input_as_handled()
		elif lore_modal and lore_modal.visible:
			_on_close_lore_modal()
			get_viewport().set_input_as_handled()
		elif pause_modal:
			if pause_modal.is_paused():
				pause_modal.close_pause()
			else:
				_on_pause_pressed()
			get_viewport().set_input_as_handled()
		return
	if (quest_dialog and quest_dialog.visible) or (shrine_modal and shrine_modal.visible) or (lore_modal and lore_modal.visible) or (pause_modal and pause_modal.is_paused()):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.is_action_pressed("ui_accept"):
			if active_relic_id != "":
				_collect_crypt_relic(active_relic_id)
			elif active_terminal_id != "":
				open_shrine_dialog(active_terminal_id)
			elif player_at_boss_gate:
				open_quest_dialog()

# ---------------------------------------------------------
# World 4 Exclusive #1: Collectible Crypt Relics -> inventory.append()
# ---------------------------------------------------------
func _get_collected_relics() -> Array:
	var list = SaveManager.user_profile.get("w4_inventory", [])
	if typeof(list) != TYPE_ARRAY:
		list = []
	return list

func _setup_collectible_relics() -> void:
	var relics_root = get_node_or_null("YSortEntities/CryptRelics")
	if not relics_root:
		return
	for relic in relics_root.get_children():
		if relic is Area2D:
			var r_id: String = relic.get_meta("relic_id", "skull_key")
			relic.body_entered.connect(func(body: Node2D):
				if body.is_in_group("Player") and not (r_id in _get_collected_relics()):
					active_relic_id = r_id
					var pr_r_in = relic.get_node_or_null("PromptLabel") as Label
					if pr_r_in:
						pr_r_in.visible = true
			)
			relic.body_exited.connect(func(body: Node2D):
				if body.is_in_group("Player"):
					if active_relic_id == r_id:
						active_relic_id = ""
					var pr_r_out = relic.get_node_or_null("PromptLabel") as Label
					if pr_r_out:
						pr_r_out.visible = false
			)
			relic.input_event.connect(func(_vp: Node, ev: InputEvent, _idx: int):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					if active_relic_id == r_id:
						_collect_crypt_relic(r_id)
			)

func _collect_crypt_relic(r_id: String) -> void:
	if not RELICS_INFO.has(r_id):
		return
	var inv = _get_collected_relics()
	if r_id in inv:
		return
	inv.append(r_id)
	SaveManager.user_profile["w4_inventory"] = inv
	var xp_gain: int = RELICS_INFO[r_id]["xp"]
	SaveManager.user_profile["xp"] = int(SaveManager.user_profile.get("xp", 0)) + xp_gain
	SaveManager.save_local_profile()

	active_relic_id = ""
	AudioManager.play_relic_pickup()
	_refresh_relic_nodes()
	_update_shrine_tracker(_get_cleared_shrines().size())
	show_toast("🏺 inventory.append('%s') ➔ %s (+%d XP!)" % [r_id, str(inv), xp_gain])

func _refresh_relic_nodes() -> void:
	var inv = _get_collected_relics()
	var relics_root = get_node_or_null("YSortEntities/CryptRelics")
	if not relics_root:
		return
	for relic in relics_root.get_children():
		if relic is Area2D:
			var r_id: String = relic.get_meta("relic_id", "")
			var collected: bool = r_id in inv
			relic.visible = not collected
			var col = relic.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if col:
				col.set_deferred("disabled", collected)

# ---------------------------------------------------------
# World 4 Exclusive #2: Crypt Portcullises & List Matrix Pedestals
# ---------------------------------------------------------
func _get_unlocked_gates() -> Array:
	var list = SaveManager.user_profile.get("w4_gates", [])
	if typeof(list) != TYPE_ARRAY:
		list = []
	return list

func _setup_matrix_gates() -> void:
	for g_id in ["gate_west", "gate_east"]:
		var node_name = "CryptGateWest" if g_id == "gate_west" else "CryptGateEast"
		var term_area = get_node_or_null("YSortEntities/" + node_name + "/TerminalArea") as Area2D
		if term_area:
			term_area.body_entered.connect(func(body: Node2D):
				if body.is_in_group("Player"):
					active_terminal_id = g_id
					var pr_in = term_area.get_node_or_null("PromptLabel") as Label
					if pr_in:
						pr_in.visible = true
			)
			term_area.body_exited.connect(func(body: Node2D):
				if body.is_in_group("Player"):
					if active_terminal_id == g_id:
						active_terminal_id = ""
					var pr_out = term_area.get_node_or_null("PromptLabel") as Label
					if pr_out:
						pr_out.visible = false
			)
			term_area.input_event.connect(func(_vp: Node, ev: InputEvent, _idx: int):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					if active_terminal_id == g_id:
						open_shrine_dialog(g_id)
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

func _refresh_gate_states() -> void:
	var unlocked = _get_unlocked_gates()
	_apply_gate_visual("CryptGateWest", "gate_west" in unlocked, "West Ossuary Portcullis")
	_apply_gate_visual("CryptGateEast", "gate_east" in unlocked, "East Sequence Portcullis")

func _apply_gate_visual(node_name: String, is_open: bool, label_title: String) -> void:
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
		term_spr.modulate = Color(0.4, 1.0, 0.75, 1.0) if is_open else Color(1.0, 0.82, 0.45, 1.0)
	if status_lbl:
		if is_open:
			status_lbl.text = "🔓 %s: RAISED" % label_title
			status_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.65))
		else:
			status_lbl.text = "🔒 %s: LOCKED" % label_title
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.72, 0.35))

# ---------------------------------------------------------
# World 4 Exclusive #3: Cycling IndexError Crypt Spike Tiles
# ---------------------------------------------------------
func _setup_index_traps() -> void:
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
				lbl.text = "🟢 list[0..2] (VALID INDEX)"
				lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.72))
			elif trap_state == 1:
				lbl.text = "🟡 idx == len - 1 (BOUNDARY)"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
			else:
				lbl.text = "🔴 IndexError: Out of Range!"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.48))

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
		player.modulate = Color(2.0, 0.35, 0.55)
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(player, "global_position", target_pos, 0.2)
		tw.parallel().tween_property(player, "modulate", Color.WHITE, 0.35)
	show_toast("⚡ IndexError: list index out of range! Cross when index is valid (Emerald)!")

# ---------------------------------------------------------
# Shrine System & Multi-Question Logic
# ---------------------------------------------------------
func _get_cleared_shrines() -> Array:
	var list = SaveManager.user_profile.get("w4_shrines", [])
	if typeof(list) != TYPE_ARRAY:
		list = []
	return list

func _refresh_all_shrine_states() -> void:
	var cleared = _get_cleared_shrines()

	if shrine_numbers and shrine_numbers.has_method("set_activated"):
		shrine_numbers.set_activated("shrine_indexing" in cleared)
	if shrine_strings and shrine_strings.has_method("set_activated"):
		shrine_strings.set_activated("shrine_mutation" in cleared)
	if shrine_booleans and shrine_booleans.has_method("set_activated"):
		shrine_booleans.set_activated("shrine_sequences" in cleared)

	_update_shrine_tracker(cleared.size())
	_update_gate_visuals(cleared)

func _update_shrine_tracker(count: int) -> void:
	if not shrine_tracker_label:
		return
	var cleared = _get_cleared_shrines()
	var inv = _get_collected_relics()
	var icon1 = "🗝️" if "shrine_indexing" in cleared else "⚪"
	var icon2 = "🏺" if "shrine_mutation" in cleared else "⚪"
	var icon3 = "🔮" if "shrine_sequences" in cleared else "⚪"
	if count >= 3:
		shrine_tracker_label.text = "✨ All 3 Shrines Awakened! [%s %s %s]  |  inventory = %s ➔ Fight Vektor-Zero!" % [icon1, icon2, icon3, str(inv)]
		shrine_tracker_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.65))
	else:
		shrine_tracker_label.text = "Shrines: %d/3 [%s %s %s]  |  inventory = %s (%d/3)" % [count, icon1, icon2, icon3, str(inv), inv.size()]
		shrine_tracker_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))

func _update_gate_visuals(cleared: Array) -> void:
	if gate_rune_1:
		gate_rune_1.modulate = Color(0.25, 0.95, 0.68, 1.0) if "shrine_indexing" in cleared else Color(0.25, 0.3, 0.4, 0.5)
	if gate_rune_2:
		gate_rune_2.modulate = Color(0.98, 0.75, 0.25, 1.0) if "shrine_mutation" in cleared else Color(0.25, 0.3, 0.4, 0.5)
	if gate_rune_3:
		gate_rune_3.modulate = Color(0.35, 0.95, 0.82, 1.0) if "shrine_sequences" in cleared else Color(0.25, 0.3, 0.4, 0.5)
	if gate_particles:
		gate_particles.emitting = (cleared.size() >= 3)

	var gate_banner = get_node_or_null("YSortEntities/TrialGate/GateBanner") as Label
	var portal_aura = get_node_or_null("YSortEntities/TrialGate/PortalAura") as Polygon2D
	var boss_statue = get_node_or_null("YSortEntities/TrialGate/BossStatue") as Sprite2D
	if cleared.size() >= 3:
		if gate_banner:
			gate_banner.text = "⚔️ BOSS UNSEALED: Vektor-Zero, The Sequence Lich"
			gate_banner.add_theme_color_override("font_color", Color(0.35, 1.0, 0.65))
		if portal_aura:
			portal_aura.color = Color(0.15, 0.85, 0.58, 0.65)
		if boss_statue:
			boss_statue.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		if gate_banner:
			gate_banner.text = "🔒 NECROPOLIS SANCTUM: Sealed (%d/3 Runes)" % cleared.size()
			gate_banner.add_theme_color_override("font_color", Color(1.0, 0.72, 0.35))
		if portal_aura:
			portal_aura.color = Color(0.12, 0.32, 0.25, 0.35)
		if boss_statue:
			boss_statue.modulate = Color(0.55, 0.68, 0.62, 0.75)

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

	var is_gate: bool = active_shrine_id.begins_with("gate_")
	var cleared_list: Array = _get_unlocked_gates() if is_gate else _get_cleared_shrines()
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
		shrine_feedback_label.text = "Select the correct Python list expression to pass Step %d of %d." % [current_shrine_q_idx + 1, total_q]
		shrine_feedback_label.add_theme_color_override("font_color", Color(0.78, 0.92, 0.85))

	shrine_action_btn.text = "⚡ Execute Expression (%d/%d)" % [current_shrine_q_idx + 1, total_q]
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
		box.bg_color = Color(0.12, 0.32, 0.26, 0.95)
		box.border_color = Color(0.95, 0.75, 0.25, 1.0)
	else:
		box.bg_color = Color(0.08, 0.18, 0.16, 0.9)
		box.border_color = Color(0.22, 0.48, 0.4, 0.8)

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
			var is_gate: bool = active_shrine_id.begins_with("gate_")
			if is_gate:
				AudioManager.play_bridge_extend()
				var gates = _get_unlocked_gates()
				if not (active_shrine_id in gates):
					gates.append(active_shrine_id)
					SaveManager.user_profile["w4_gates"] = gates
					SaveManager.user_profile["xp"] = int(SaveManager.user_profile.get("xp", 0)) + reward_xp
					SaveManager.save_local_profile()
					BadgeManager.check_all_badges()
					shrine_feedback_label.text = "🔓 Crypt Portcullis Raised! (+%d XP) %s" % [reward_xp, q_data["explanation"]]
					show_toast("🏺 %s Unsealed! (+%d XP)" % [data["title"], reward_xp])
				else:
					shrine_feedback_label.text = "🔓 %s Verified! %s" % [data["title"], q_data["explanation"]]
				shrine_feedback_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
				shrine_action_btn.text = "Enter Crypt Wing ✨"
				_refresh_gate_states()
				_update_shrine_tracker(_get_cleared_shrines().size())
			else:
				AudioManager.play_shrine_awaken()
				var cleared = _get_cleared_shrines()
				if not (active_shrine_id in cleared):
					cleared.append(active_shrine_id)
					SaveManager.user_profile["w4_shrines"] = cleared
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
		shrine_feedback_label.text = "❌ Not quite! Review the Lists & Sequences Lesson above and try another option."
		shrine_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.45))

func _on_close_shrine_modal() -> void:
	shrine_modal.visible = false
	if player:
		player.can_move = true

# ---------------------------------------------------------
# Catacomb NPCs Dialog & Reward System
# ---------------------------------------------------------
func _get_helped_npcs() -> Array:
	var list = SaveManager.user_profile.get("w4_npcs_helped", [])
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

	show_toast("📦 Found Catacomb Tablet: %s (+%d XP!)" % [title, xp])

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
		_update_dialog_speaker("💀", "Vektor-Zero • The Catacomb Sequence Lich", "res://assets/sprites/portraits/portrait_vektor.png")
		if quest_text:
			quest_text.text = "Supreme mastery of sequences, Adventurer Alex! All 3 Catacomb List Shrines are awakened!\n\nBeyond this Necropolis Altar waits VEKTOR-ZERO, THE CATACOMB SEQUENCE LICH (500 HP). Use zero-based indexing 'list[0]', negative indexing 'list[-1]', '.append()', and 'len()' to shatter his Phylactery Array!"
		if accept_btn:
			accept_btn.text = "⚔️ Fight Boss: Vektor-Zero"
			accept_btn.disabled = false
		if decline_btn:
			decline_btn.text = "Prepare More"
	else:
		_update_dialog_speaker("🧙‍♂️", "Master PyWizard • Guardian of the Necropolis Matrix", "res://assets/sprites/portraits/portrait_pywizard.png")
		var missing: PackedStringArray = []
		if not ("shrine_indexing" in cleared):
			missing.append("• Shrine of Indexing (Southwest Crypt Alcove — 4 Questions)")
		if not ("shrine_mutation" in cleared):
			missing.append("• Shrine of Mutation (West Ossuary Wing via West Matrix Pedestal — 4 Questions)")
		if not ("shrine_sequences" in cleared):
			missing.append("• Shrine of Sequences (East Tablet Wing via East Matrix Pedestal — 4 Questions)")

		if quest_text:
			quest_text.text = "Halt, young coder! The Necropolis Sanctum of Vektor-Zero is sealed by 3 Ancient Sequence Runes (%d/3 Awakened).\n\nUnlock the West & East Matrix Portcullises and awaken the remaining Shrines:\n%s" % [count, "\n".join(missing)]
		if accept_btn:
			if SaveManager.is_dev_mode():
				accept_btn.text = "🛠️ Dev: Bypass Seal & Fight Vektor-Zero!"
				accept_btn.disabled = false
			else:
				accept_btn.text = "🔒 Sealed (%d/3 Runes)" % count
				accept_btn.disabled = true
		if decline_btn:
			decline_btn.text = "Explore Catacombs"

	quest_dialog.visible = true
	AudioManager.play_npc_chat()

func _on_accept_quest() -> void:
	if active_dialog_mode != "boss":
		var npc_id = active_dialog_mode
		var helped = _get_helped_npcs()
		if not (npc_id in helped) and NPCS_DATA.has(npc_id):
			helped.append(npc_id)
			SaveManager.user_profile["w4_npcs_helped"] = helped
			var xp_gain: int = NPCS_DATA[npc_id]["xp"]
			SaveManager.user_profile["xp"] = int(SaveManager.user_profile.get("xp", 0)) + xp_gain
			SaveManager.user_profile["hint_tokens"] = int(SaveManager.user_profile.get("hint_tokens", 5)) + 1
			SaveManager.save_local_profile()
			BadgeManager.check_all_badges()
			_refresh_all_npc_states()
			show_toast("🎁 +%d XP & +1 Hint Token from %s!" % [xp_gain, NPCS_DATA[npc_id]["name"].split("•")[0].strip_edges()])
		_on_close_quest_dialog()
		return

	if _get_cleared_shrines().size() < 3 and not SaveManager.is_dev_mode():
		show_toast("🔒 Awaken all 3 Shrines first to unseal the Boss Battle!")
		return
	SaveManager.user_profile["current_level"] = 4
	SaveManager.save_local_profile()
	quest_dialog.visible = false
	SceneManager.change_scene_with_loading(SceneManager.LEVEL_GAMEPLAY)

func _on_close_quest_dialog() -> void:
	quest_dialog.visible = false
	if player:
		player.can_move = true

func start_quiz(_json_path: String) -> void:
	open_quest_dialog()

func _on_pause_pressed() -> void:
	if pause_modal:
		pause_modal.open_pause()
	if player:
		player.can_move = false
	if joystick:
		joystick.visible = false

func _on_pause_resumed() -> void:
	if player:
		player.can_move = true
	if joystick:
		joystick.visible = bool(SaveManager.get_setting("show_joystick", true))

func _on_pause_respawn() -> void:
	_on_pause_resumed()
	if player and spawn_position != Vector2.ZERO:
		player.global_position = spawn_position

func _on_back_to_select() -> void:
	SceneManager.change_scene_with_loading(SceneManager.LEVEL_SELECT)

func dev_unseal_and_teleport_boss() -> void:
	SaveManager.user_profile["w4_gates"] = ["gate_west", "gate_east"]
	SaveManager.user_profile["w4_shrines"] = ["shrine_indexing", "shrine_mutation", "shrine_sequences"]
	_refresh_gate_states()
	_refresh_all_shrine_states()
	if player:
		player.global_position = Vector2(1200, 235)
	show_toast("🛠️ Dev Mode: All World 4 Portcullises & Shrines Unsealed + Teleported to Boss Gate!")

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

