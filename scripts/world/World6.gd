# res://scripts/world/World6.gd
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

# Prism & Siege UI Nodes
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

# Throne Gate Nodes
@onready var gate_rune_1: Sprite2D = $YSortEntities/TrialGate/Rune1
@onready var gate_rune_2: Sprite2D = $YSortEntities/TrialGate/Rune2
@onready var gate_rune_3: Sprite2D = $YSortEntities/TrialGate/Rune3
@onready var gate_rune_4: Sprite2D = $YSortEntities/TrialGate/Rune4
@onready var gate_particles: CPUParticles2D = $YSortEntities/TrialGate/GateParticles

var active_seal_id: String = ""
var current_seal_q_idx: int = 0
var seal_question_answered: bool = false
var selected_option_idx: int = -1
var active_dialog_mode: String = "boss"
var toast_tween: Tween
var boss_anim_timer: float = 0.0
var glitch_cycle_timer: float = 0.0
var trap_state: int = 0 # 0 = STABLE, 1 = TELEGRAPH WARNING, 2 = GLITCH BEAM STRIKE!
var active_beam_pattern: int = 0 # Alternates between lanes (0 = Outer Lanes, 1 = Center & Cross Lanes)
var trap_cooldown: float = 0.0
var active_terminal_id: String = ""
var player_at_boss_gate: bool = false
var bottom_dialog_bar: CanvasLayer = null

var glitch_arena_drawer: Node2D = null
var allied_general_sprites: Array[Sprite2D] = []
var glitch_orbs: Array[Dictionary] = []

const SEAL_ORDER: Array[String] = ["prism_nullbyte", "prism_chronos", "prism_lambda", "prism_vektor"]

const BEAM_LANES_PATTERN_A: Array[Rect2] = [
	Rect2(780, 505, 840, 74),
	Rect2(780, 785, 840, 74)
]

const BEAM_LANES_PATTERN_B: Array[Rect2] = [
	Rect2(780, 645, 840, 74),
	Rect2(980, 485, 90, 390),
	Rect2(1330, 485, 90, 390)
]

const NPCS_DATA: Dictionary = {
	"npc_mentor_sera": {
		"name": "Master PyWizard • Grand Archmage of Pythonia",
		"icon": "🧙‍♂️",
		"portrait": "res://assets/sprites/portraits/portrait_pywizard.png",
		"xp": 150,
		"dialog": "Alex! We have breached the Royal Citadel Sanctum, and all 5 Awakened Boss Generals are fighting at your side!\n\nLord SegFault is firing real-time Crimson Glitch Beams and patrolling Null-Orbs across the central runic floor. Dodge the red telegraph zones and help each General hack their Prism Terminal:\n• Prism I (Bottom-Left • NullByte): Purges outer Null-Orbs!\n• Prism II (Top-Left • Chronos-If): Slows SegFault's Glitch Hazards by 40%!\n• Prism III (Top-Right • Lambda-Prime): Grants +30% Arcane Move Speed!\n• Prism IV (Bottom-Right • Vektor-Zero): Projects a Golden Safe Corridor!\n\nTake my Archmage Blessing (+150 XP & +1 Hint Token)!"
	},
	"npc_mentor_kael": {
		"name": "General Ignis-Py • Awakened Guardian of the Spire",
		"icon": "🐉",
		"portrait": "res://assets/sprites/portraits/portrait_ignis.png",
		"xp": 150,
		"dialog": "ROAAAR! My volcanic flames are yours to command, young Grandmaster!\n\nOnce you and my four fellow Generals breach all 4 Prism Terminals, Lord SegFault's invincibility barrier around Princess Ada's cage will shatter!\n\nEven better: during the Final Boss Showdown against SegFault, all 5 of us will appear on your Battle HUD with clickable General Assist Skills—including my Obsidian Nova strike!\n\nTake this Dragon Vanguard Blessing (+150 XP & +1 Hint Token)!"
	}
}

const SEALS_DATA: Dictionary = {
	"prism_nullbyte": {
		"title": "Prism I: NullByte's Variable Purge",
		"node_name": "SealGate1",
		"icon": "🟢",
		"color": Color(0.2, 0.95, 0.55),
		"topic": "General NullByte Co-Op • Variables, Slicing & String Purification",
		"lesson": "[b]General NullByte's Briefing:[/b]\n• \"SegFault corrupted my memory registers with null pointers! Help me slice away the glitch prefix and cast the key to an integer.\"\n• [code]text[a:b][/code] extracts characters from index [code]a[/code] up to (but excluding) [code]b[/code].\n• [code]Aura Reward:[/code] Purges 2 patrolling Null-Glitch Orbs & readies [b]50/50 Glitch Purge[/b] in battle!",
		"xp": 200,
		"questions": [
			{
				"question": "NullByte intercepts [code]packet = \"ERR_4096_OK\"[/code]. Which expression extracts [code]4096[/code] as an integer?",
				"options": [
					"int(packet[4:8])",
					"str(packet[4:8])",
					"int(packet[3:7])",
					"packet[4:8]"
				],
				"correct_index": 0,
				"explanation": "'packet[4:8]' slices characters 4, 5, 6, 7 ('4096'), and 'int()' converts it to the integer 4096!"
			},
			{
				"question": "What value is stored in [code]clean[/code] after:\n[code]raw = \"  ada_key  \"\nclean = raw.strip().upper()[/code]",
				"options": [
					"\"ADA_KEY\"",
					"\"  ADA_KEY  \"",
					"\"ada_key\"",
					"7"
				],
				"correct_index": 0,
				"explanation": "'.strip()' removes leading/trailing spaces and '.upper()' converts the string to uppercase \"ADA_KEY\"!"
			}
		]
	},
	"prism_chronos": {
		"title": "Prism II: Chronos's Time Stabilizer",
		"node_name": "SealGate2",
		"icon": "🔵",
		"color": Color(0.22, 0.78, 0.98),
		"topic": "General Chronos-If Co-Op • Loop Control & Temporal Logic",
		"lesson": "[b]General Chronos-If's Briefing:[/b]\n• \"SegFault overclocked the Citadel's hazard timers into an infinite loop! Inject a clean termination condition to slow his beams.\"\n• [code]range(start, stop, step)[/code] steps through time intervals; [code]break[/code] exits a loop immediately.\n• [code]Aura Reward:[/code] Slows all Citadel Glitch Hazards by 40% & readies [b]Temporal Shield[/b] in battle!",
		"xp": 200,
		"questions": [
			{
				"question": "How many times does Chronos's stabilizer pulse in:\n[code]pulses = 0\nfor t in range(10, 0, -3):\n    pulses += 1[/code]",
				"options": [
					"4 times (t = 10, 7, 4, 1)",
					"3 times (t = 10, 7, 4)",
					"10 times",
					"Infinite loop"
				],
				"correct_index": 0,
				"explanation": "Starting at 10 and stepping by -3 while > 0 visits t = 10, 7, 4, and 1 — 4 pulses total!"
			},
			{
				"question": "What is the value of [code]shield[/code] after this loop finishes?\n[code]shield = 0\nfor n in [2, 4, 9, 6]:\n    if n % 2 != 0:\n        break\n    shield += n[/code]",
				"options": [
					"6 (adds 2 and 4, then breaks at odd number 9)",
					"12 (adds 2, 4, and 6)",
					"21 (adds all numbers)",
					"0"
				],
				"correct_index": 0,
				"explanation": "2 and 4 are even (shield becomes 6); when n is 9, 'n % 2 != 0' is True so 'break' exits the loop immediately!"
			}
		]
	},
	"prism_lambda": {
		"title": "Prism III: Lambda's Arcane Conduit",
		"node_name": "SealGate3",
		"icon": "🟣",
		"color": Color(0.75, 0.42, 0.98),
		"topic": "General Lambda-Prime Co-Op • Functions, Default Args & Return",
		"lesson": "[b]General Lambda-Prime's Briefing:[/b]\n• \"My modular conduits are ready, Alex! Route the return values cleanly to supercharge your arcane boots and spell power.\"\n• Functions can define default parameters like [code]def boost(base, mult=2):[/code].\n• [code]Aura Reward:[/code] Grants +30% Arcane Move Speed & readies [b]2x Arcane Overcharge[/b] in battle!",
		"xp": 200,
		"questions": [
			{
				"question": "What does [code]amplify(5) + amplify(3, 4)[/code] evaluate to?\n[code]def amplify(mana, factor=2):\n    return mana * factor[/code]",
				"options": [
					"22 (amplify(5) is 10, amplify(3, 4) is 12)",
					"16",
					"20",
					"TypeError: missing argument"
				],
				"correct_index": 0,
				"explanation": "'amplify(5)' uses default factor=2 -> 10. 'amplify(3, 4)' overrides factor=4 -> 12. 10 + 12 = 22!"
			},
			{
				"question": "What is returned by [code]purify([1, -2, 3, -4, 5])[/code]?\n[code]def purify(nodes):\n    return [x for x in nodes if x > 0][/code]",
				"options": [
					"[1, 3, 5] (filters only positive numbers)",
					"[-2, -4]",
					"9",
					"[True, False, True, False, True]"
				],
				"correct_index": 0,
				"explanation": "The list comprehension keeps only elements where 'x > 0', producing [1, 3, 5]!"
			}
		]
	},
	"prism_vektor": {
		"title": "Prism IV: Vektor's Matrix Relay",
		"node_name": "SealGate4",
		"icon": "🟠",
		"color": Color(0.98, 0.75, 0.2),
		"topic": "General Vektor-Zero Co-Op • Dictionaries, Lists & Keystones",
		"lesson": "[b]General Vektor-Zero's Briefing:[/b]\n• \"The final Prism uses nested dictionaries and arrays! Align the key-value coordinates to project a golden shield corridor straight to the Throne!\"\n• Access dictionary values via [code]d[key][/code] or [code]d.get(key, default)[/code].\n• [code]Aura Reward:[/code] Projects a Golden Safe Corridor in the center & readies [b]Matrix Auto-Lock[/b] in battle!",
		"xp": 200,
		"questions": [
			{
				"question": "What does this dictionary lookup evaluate to?\n[code]citadel = {\"wards\": [10, 20, 30], \"core\": 50}\nresult = citadel[\"wards\"][-1] + citadel[\"core\"][/code]",
				"options": [
					"80 (30 + 50)",
					"60 (10 + 50)",
					"110",
					"KeyError"
				],
				"correct_index": 0,
				"explanation": "'citadel[\"wards\"][-1]' is the last element of the list (30), plus 'citadel[\"core\"]' (50) = 80!"
			},
			{
				"question": "After running this code, what is [code]len(keys)[/code]?\n[code]keys = [\"emerald\", \"azure\", \"violet\"]\nkeys.append(\"amber\")\nkeys.pop(0)[/code]",
				"options": [
					"3 (appends 1 item -> 4, then pops index 0 -> 3)",
					"4",
					"2",
					"\"emerald\""
				],
				"correct_index": 0,
				"explanation": "Starting with 3 items, '.append()' makes 4, and '.pop(0)' removes the first item, leaving 3 items!"
			}
		]
	}
}

func _ready() -> void:
	SaveManager.user_profile["current_level"] = 6
	SaveManager.save_local_profile()

	if joystick:
		joystick.visible = bool(SaveManager.get_setting("show_joystick", true))

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
		shrine_action_btn.connect("pressed", _on_shrine_action)

	if lore_close_btn and not lore_close_btn.pressed.is_connected(_on_close_lore_modal):
		lore_close_btn.pressed.connect(_on_close_lore_modal)

	# Customize World 6 Chests & Slimes
	var chest1 = get_node_or_null("YSortEntities/Chests/Chest1")
	if chest1:
		chest1.chest_id = "w6_chest_generals"
		chest1.lore_title = "Codex of the Five Generals"
		chest1.lore_text = "Royal Archive I: Before Lord SegFault's invasion, NullByte, Chronos-If, Lambda-Prime, Vektor-Zero, and Ignis-Py served Princess Ada as the Five Grand Guardians of Pythonia's core syntax."
	var chest2 = get_node_or_null("YSortEntities/Chests/Chest2")
	if chest2:
		chest2.chest_id = "w6_chest_ada"
		chest2.lore_title = "Princess Ada's Source Prism"
		chest2.lore_text = "Royal Archive II: When all 4 Prism Terminals are overridden, the 5 Generals can channel their power directly into Alex's Battle HUD during the final duel against Lord SegFault!"

	var slime1 = get_node_or_null("YSortEntities/Slimes/Slime1")
	if slime1:
		slime1.slime_name = "Royal Cyber-Slime"
		slime1.quote_text = "Bzzzt! Dodge the red Glitch Beam lanes on the central floor and hack the 4 corner Prisms with the Boss Generals! ⚡"
	var slime2 = get_node_or_null("YSortEntities/Slimes/Slime2")
	if slime2:
		slime2.slime_name = "Sanctum Slime"
		slime2.quote_text = "Sparkle! Each General you help activates a Field Aura that makes the Citadel hazards easier to survive! 👑"

	_spawn_allied_generals()
	_setup_realtime_glitch_arena()
	_setup_seal_gates()
	_setup_magma_traps()

	var p_name = SaveManager.user_profile.get("full_name", "Adventurer Alex")
	if area_title_label:
		area_title_label.text = "🏰 The Royal Citadel Sanctum  |  %s" % p_name

	_refresh_all_seal_states()
	_refresh_all_npc_states()

	AudioManager.play_boss_theme(5)

	var bdb_scene = load("res://scenes/ui/BottomDialogBar.tscn")
	if bdb_scene:
		bottom_dialog_bar = bdb_scene.instantiate()
		add_child(bottom_dialog_bar)
		bottom_dialog_bar.dialog_finished.connect(func():
			if player and (not quest_dialog or not quest_dialog.visible) and (not shrine_modal or not shrine_modal.visible):
				player.can_move = true
		)
		if SaveManager.should_play_world_intro(6):
			if player:
				player.can_move = false
			bottom_dialog_bar.play_world_intro(6)

# ---------------------------------------------------------
# Spawn the 5 Allied Boss Generals & Princess Ada's Prism
# ---------------------------------------------------------
func _spawn_allied_generals() -> void:
	var ysort = get_node_or_null("YSortEntities")
	if not ysort:
		return

	# Set the Throne BossStatue to Lord SegFault's custom spritesheet!
	var throne_boss = get_node_or_null("YSortEntities/TrialGate/BossStatue") as Sprite2D
	if throne_boss:
		throne_boss.texture = load("res://assets/sprites/custom/boss_segfault_sheet.png")
		throne_boss.scale = Vector2(2.6, 2.6)
		throne_boss.modulate = Color.WHITE

	var generals_cfg = [
		{
			"name": "🟢 General NullByte [Allied]",
			"pos": Vector2(345, 985),
			"sheet": "res://assets/sprites/custom/boss_golem_sheet.png",
			"color": Color(0.35, 1.0, 0.65),
			"flip": false
		},
		{
			"name": "🔵 General Chronos-If [Allied]",
			"pos": Vector2(345, 260),
			"sheet": "res://assets/sprites/custom/boss_warden_sheet.png",
			"color": Color(0.4, 0.85, 1.0),
			"flip": false
		},
		{
			"name": "🟣 General Lambda-Prime [Allied]",
			"pos": Vector2(2065, 260),
			"sheet": "res://assets/sprites/custom/boss_arbiter_sheet.png",
			"color": Color(0.85, 0.55, 1.0),
			"flip": true
		},
		{
			"name": "🟠 General Vektor-Zero [Allied]",
			"pos": Vector2(2065, 985),
			"sheet": "res://assets/sprites/custom/boss_index_warden_sheet.png",
			"color": Color(1.0, 0.82, 0.35),
			"flip": true
		},
		{
			"name": "🔴 General Ignis-Py [Allied]",
			"pos": Vector2(2175, 645),
			"sheet": "res://assets/sprites/custom/boss_guardian_sheet.png",
			"color": Color(1.0, 0.45, 0.35),
			"flip": true
		}
	]

	for g in generals_cfg:
		var holder := Node2D.new()
		holder.position = g["pos"]
		ysort.add_child(holder)

		var spr := Sprite2D.new()
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if ResourceLoader.exists(g["sheet"]):
			spr.texture = load(g["sheet"])
		spr.hframes = 6
		spr.vframes = 10
		spr.frame = 6
		spr.scale = Vector2(1.85, 1.85)
		spr.flip_h = g["flip"]
		holder.add_child(spr)
		allied_general_sprites.append(spr)

		var lbl := Label.new()
		lbl.text = g["name"]
		lbl.position = Vector2(-110, -72)
		lbl.size = Vector2(220, 22)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", g["color"])
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		holder.add_child(lbl)

	# Princess Ada's Crystal Prism Cage beside the Throne
	var ada_holder := Node2D.new()
	ada_holder.position = Vector2(1385, 225)
	ysort.add_child(ada_holder)

	var ada_lbl := Label.new()
	ada_lbl.text = "👑 Princess Ada [Trapped in Glitch Prism]"
	ada_lbl.position = Vector2(-140, -68)
	ada_lbl.size = Vector2(280, 24)
	ada_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ada_lbl.add_theme_font_size_override("font_size", 12)
	ada_lbl.add_theme_color_override("font_color", Color(0.98, 0.75, 0.95))
	ada_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	ada_lbl.add_theme_constant_override("shadow_offset_y", 1)
	ada_holder.add_child(ada_lbl)

# ---------------------------------------------------------
# Real-Time Glitch Survival Arena (Beams & Patrolling Null-Orbs)
# ---------------------------------------------------------
func _setup_realtime_glitch_arena() -> void:
	glitch_arena_drawer = Node2D.new()
	glitch_arena_drawer.name = "GlitchArenaDrawer"
	glitch_arena_drawer.z_index = 1
	add_child(glitch_arena_drawer)
	move_child(glitch_arena_drawer, 1)
	glitch_arena_drawer.draw.connect(_on_draw_glitch_arena)

	var orb_configs = [
		{"center": Vector2(980, 680), "radius": Vector2(180, 130), "speed": 1.65, "phase": 0.0, "purged_by_nullbyte": true},
		{"center": Vector2(1420, 680), "radius": Vector2(180, 130), "speed": -1.65, "phase": 1.57, "purged_by_nullbyte": true},
		{"center": Vector2(1200, 580), "radius": Vector2(290, 85), "speed": 1.35, "phase": 3.14, "purged_by_nullbyte": false},
		{"center": Vector2(1200, 780), "radius": Vector2(290, 85), "speed": -1.35, "phase": 4.71, "purged_by_nullbyte": false}
	]

	var orb_tex = load("res://assets/sprites/custom/rune_orb.png")
	for i in range(orb_configs.size()):
		var cfg = orb_configs[i]
		var orb_node := Node2D.new()
		orb_node.position = cfg["center"]
		glitch_arena_drawer.add_child(orb_node)

		var spr := Sprite2D.new()
		if orb_tex:
			spr.texture = orb_tex
		spr.scale = Vector2(1.35, 1.35)
		spr.modulate = Color(1.0, 0.18, 0.45, 0.95)
		orb_node.add_child(spr)

		var tag := Label.new()
		tag.text = "👾 Null-Orb"
		tag.position = Vector2(-45, -38)
		tag.size = Vector2(90, 18)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_theme_font_size_override("font_size", 10)
		tag.add_theme_color_override("font_color", Color(1.0, 0.45, 0.65))
		tag.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		orb_node.add_child(tag)

		glitch_orbs.append({
			"node": orb_node,
			"center": cfg["center"],
			"radius": cfg["radius"],
			"speed": cfg["speed"],
			"phase": cfg["phase"],
			"purged_by_nullbyte": cfg["purged_by_nullbyte"],
			"active": true
		})

func _on_draw_glitch_arena() -> void:
	var unlocked = _get_unlocked_seals()
	var has_vektor_corridor: bool = ("prism_vektor" in unlocked)

	# Draw Vektor's Golden Safe Corridor down the center if Prism IV is hacked!
	if has_vektor_corridor:
		var safe_rect := Rect2(1130, 470, 140, 420)
		glitch_arena_drawer.draw_rect(safe_rect, Color(0.98, 0.82, 0.2, 0.16), true)
		glitch_arena_drawer.draw_rect(safe_rect, Color(1.0, 0.88, 0.35, 0.75), false, 2.5)

	var active_lanes: Array[Rect2] = BEAM_LANES_PATTERN_A if (active_beam_pattern == 0) else BEAM_LANES_PATTERN_B
	var pulse: float = 0.5 + 0.5 * sin(boss_anim_timer * 10.0)

	for rect in active_lanes:
		if trap_state == 0:
			# Subtle cyan circuit outline while dormant
			glitch_arena_drawer.draw_rect(rect, Color(0.2, 0.85, 1.0, 0.08), true)
			glitch_arena_drawer.draw_rect(rect, Color(0.2, 0.85, 1.0, 0.25), false, 1.5)
		elif trap_state == 1:
			# Telegraph warning (pulsing amber/red)
			glitch_arena_drawer.draw_rect(rect, Color(1.0, 0.55, 0.1, 0.18 + 0.18 * pulse), true)
			glitch_arena_drawer.draw_rect(rect, Color(1.0, 0.75, 0.2, 0.85), false, 2.5)
		elif trap_state == 2:
			# Active SegFault Crimson Glitch Beam Strike!
			glitch_arena_drawer.draw_rect(rect, Color(0.95, 0.12, 0.38, 0.52 + 0.2 * pulse), true)
			var core_rect := rect.grow(-14.0)
			glitch_arena_drawer.draw_rect(core_rect, Color(1.0, 0.75, 0.9, 0.85), true)
			glitch_arena_drawer.draw_rect(rect, Color(1.0, 0.2, 0.55, 0.98), false, 3.5)

func _process(delta: float) -> void:
	boss_anim_timer += delta
	if trap_cooldown > 0.0:
		trap_cooldown -= delta

	var unlocked = _get_unlocked_seals()
	var speed_mult: float = 0.60 if ("prism_chronos" in unlocked) else 1.0
	glitch_cycle_timer += delta * speed_mult

	# Animate Throne Boss & 5 Allied Generals
	var boss_statue = get_node_or_null("YSortEntities/TrialGate/BossStatue") as Sprite2D
	if boss_statue and boss_statue.hframes >= 6:
		boss_statue.frame = 6 + (int(boss_anim_timer * 5.0) % 6)

	for gen_spr in allied_general_sprites:
		if is_instance_valid(gen_spr) and gen_spr.hframes >= 6:
			gen_spr.frame = 6 + (int(boss_anim_timer * 5.0) % 6)

	# Cycle SegFault Glitch Beams (0 = Stable [2.2s], 1 = Telegraph [1.1s], 2 = Strike [1.1s])
	var cycle_len: float = 4.4
	var cycle_idx: int = int(glitch_cycle_timer / cycle_len)
	var cycle_pos: float = fmod(glitch_cycle_timer, cycle_len)
	active_beam_pattern = cycle_idx % 2

	var new_state = 0
	if cycle_pos < 2.2:
		new_state = 0
	elif cycle_pos < 3.3:
		new_state = 1
	else:
		new_state = 2

	if new_state != trap_state:
		trap_state = new_state
		_update_trap_visuals()

	# Move real-time patrolling Null-Glitch Orbs
	var nullbyte_purged: bool = ("prism_nullbyte" in unlocked)
	for orb in glitch_orbs:
		var orb_node: Node2D = orb["node"]
		if not is_instance_valid(orb_node):
			continue
		if nullbyte_purged and orb["purged_by_nullbyte"]:
			orb_node.visible = false
			orb["active"] = false
			continue
		orb_node.visible = true
		orb["active"] = true
		var angle: float = orb["phase"] + glitch_cycle_timer * float(orb["speed"])
		var rad: Vector2 = orb["radius"]
		var ctr: Vector2 = orb["center"]
		orb_node.position = ctr + Vector2(cos(angle) * rad.x, sin(angle) * rad.y)

	if glitch_arena_drawer:
		glitch_arena_drawer.queue_redraw()

	if trap_cooldown <= 0.0:
		_check_realtime_glitch_collisions(unlocked)

func _check_realtime_glitch_collisions(unlocked: Array) -> void:
	if not player or not player.can_move:
		return
	var p_pos: Vector2 = player.global_position
	var in_vektor_safe_corridor: bool = ("prism_vektor" in unlocked) and Rect2(1130, 470, 140, 420).has_point(p_pos)

	# 1. Check active Glitch Beam lanes during State 2
	if trap_state == 2 and not in_vektor_safe_corridor:
		var active_lanes: Array[Rect2] = BEAM_LANES_PATTERN_A if (active_beam_pattern == 0) else BEAM_LANES_PATTERN_B
		for rect in active_lanes:
			if rect.has_point(p_pos):
				_trigger_glitch_hit(rect.get_center(), "⚡ Hit by SegFault's Glitch Beam! Cross when lanes are Cyan (Stable)!")
				return

	# 2. Check patrolling Null-Glitch Orbs
	for orb in glitch_orbs:
		if not orb["active"]:
			continue
		var orb_node: Node2D = orb["node"]
		if is_instance_valid(orb_node) and p_pos.distance_to(orb_node.global_position) < 36.0:
			_trigger_glitch_hit(orb_node.global_position, "👾 Hit by a patrolling Null-Orb! Hack NullByte & Chronos's Prisms to weaken them!")
			return

	# 3. Check legacy ConditionTraps
	if trap_state == 2:
		_check_player_in_armed_trap()

func _trigger_glitch_hit(hazard_pos: Vector2, msg: String) -> void:
	trap_cooldown = 1.25
	AudioManager.play_error()
	if player:
		var push_dir = (player.global_position - hazard_pos).normalized()
		if push_dir.length() < 0.1:
			push_dir = Vector2(0, 1)
		var target_pos = player.global_position + push_dir * 68.0
		target_pos.x = clampf(target_pos.x, 160.0, 2240.0)
		target_pos.y = clampf(target_pos.y, 180.0, 1220.0)
		player.modulate = Color(2.4, 0.25, 0.55)
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(player, "global_position", target_pos, 0.2)
		tw.parallel().tween_property(player, "modulate", Color.WHITE, 0.35)
	show_toast(msg)

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
			if active_terminal_id != "":
				open_shrine_dialog(active_terminal_id)
			elif player_at_boss_gate:
				open_quest_dialog()

# ---------------------------------------------------------
# 4 Citadel Prism Terminals & General Field Auras
# ---------------------------------------------------------
func _get_unlocked_seals() -> Array:
	var list = SaveManager.user_profile.get("w6_prisms", [])
	if typeof(list) != TYPE_ARRAY:
		list = []
	return list

func _setup_seal_gates() -> void:
	for s_id in SEAL_ORDER:
		var node_name: String = SEALS_DATA[s_id]["node_name"]
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

func _refresh_all_seal_states() -> void:
	var unlocked = _get_unlocked_seals()
	for s_id in SEAL_ORDER:
		var info = SEALS_DATA[s_id]
		var is_open: bool = s_id in unlocked
		_apply_seal_visual(info["node_name"], is_open, info["title"], info["color"])

	# Apply Lambda-Prime's +30% Arcane Speed Aura to Alex!
	if player and "speed" in player:
		player.speed = 310.0 if ("prism_lambda" in unlocked) else 240.0

	_update_seal_tracker(unlocked)
	_update_throne_visuals(unlocked)

func _apply_seal_visual(node_name: String, is_open: bool, label_title: String, theme_col: Color) -> void:
	var gate_node = get_node_or_null("YSortEntities/" + node_name) as Node2D
	if not gate_node:
		return
	var laser = gate_node.get_node_or_null("LaserBarrier") as Sprite2D
	var status_lbl = gate_node.get_node_or_null("TerminalArea/StatusLabel") as Label
	var term_spr = gate_node.get_node_or_null("TerminalArea/TerminalSprite") as Sprite2D

	if laser:
		laser.visible = not is_open
		laser.modulate = theme_col
	if term_spr:
		term_spr.modulate = Color(0.4, 1.0, 0.75, 1.0) if is_open else theme_col
	if status_lbl:
		if is_open:
			status_lbl.text = "✅ %s: OVERRIDDEN (AURA ACTIVE)" % label_title
			status_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.65))
		else:
			status_lbl.text = "🔒 %s: CORRUPTED" % label_title
			status_lbl.add_theme_color_override("font_color", theme_col)

func _update_seal_tracker(unlocked: Array) -> void:
	if not shrine_tracker_label:
		return
	var p1 = "🟢" if "prism_nullbyte" in unlocked else "⚪"
	var p2 = "🔵" if "prism_chronos" in unlocked else "⚪"
	var p3 = "🟣" if "prism_lambda" in unlocked else "⚪"
	var p4 = "🟠" if "prism_vektor" in unlocked else "⚪"
	var count = unlocked.size()
	if count >= 4:
		shrine_tracker_label.text = "👑 All 4 Prisms Breached & 5 Generals Ready! [%s %s %s %s] ➔ Confront Lord SegFault!" % [p1, p2, p3, p4]
		shrine_tracker_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	else:
		shrine_tracker_label.text = "Citadel Siege Prisms: %d/4 [%s %s %s %s]  |  Dodge Glitch Beams & Aid the 5 Generals" % [count, p1, p2, p3, p4]
		shrine_tracker_label.add_theme_color_override("font_color", Color(0.92, 0.75, 1.0))

func _update_throne_visuals(unlocked: Array) -> void:
	if gate_rune_1:
		gate_rune_1.modulate = Color(0.2, 0.95, 0.55, 1.0) if "prism_nullbyte" in unlocked else Color(0.25, 0.3, 0.4, 0.5)
	if gate_rune_2:
		gate_rune_2.modulate = Color(0.22, 0.78, 0.98, 1.0) if "prism_chronos" in unlocked else Color(0.25, 0.3, 0.4, 0.5)
	if gate_rune_3:
		gate_rune_3.modulate = Color(0.75, 0.42, 0.98, 1.0) if "prism_lambda" in unlocked else Color(0.25, 0.3, 0.4, 0.5)
	if gate_rune_4:
		gate_rune_4.modulate = Color(0.98, 0.75, 0.2, 1.0) if "prism_vektor" in unlocked else Color(0.25, 0.3, 0.4, 0.5)
	if gate_particles:
		gate_particles.emitting = (unlocked.size() >= 4)

	var gate_banner = get_node_or_null("YSortEntities/TrialGate/GateBanner") as Label
	var portal_aura = get_node_or_null("YSortEntities/TrialGate/PortalAura") as Polygon2D
	var boss_statue = get_node_or_null("YSortEntities/TrialGate/BossStatue") as Sprite2D
	if unlocked.size() >= 4:
		if gate_banner:
			gate_banner.text = "⚡ SHIELD SHATTERED: Confront Lord SegFault & Rescue Princess Ada!"
			gate_banner.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
		if portal_aura:
			portal_aura.color = Color(0.85, 0.15, 0.55, 0.65)
		if boss_statue:
			boss_statue.modulate = Color.WHITE
	else:
		if gate_banner:
			gate_banner.text = "🔒 THRONE BARRIER ACTIVE: Hack All 4 Generals' Prisms (%d/4)" % unlocked.size()
			gate_banner.add_theme_color_override("font_color", Color(1.0, 0.45, 0.65))
		if portal_aura:
			portal_aura.color = Color(0.45, 0.08, 0.28, 0.45)
		if boss_statue:
			boss_statue.modulate = Color(0.75, 0.65, 0.85, 0.85)

# ---------------------------------------------------------
# Central Glitch Vent Nodes
# ---------------------------------------------------------
func _setup_magma_traps() -> void:
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
				lbl.text = "🟢 Glitch Grid: STABLE"
				lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.72))
			elif trap_state == 1:
				lbl.text = "⚠️ Glitch Beam: CHARGING..."
				lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
			else:
				lbl.text = "🔴 SegFault: GLITCH STRIKE!"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.55))

func _check_player_in_armed_trap() -> void:
	var traps_root = get_node_or_null("YSortEntities/ConditionTraps")
	if not traps_root or not player:
		return
	for trap in traps_root.get_children():
		if trap is Area2D and trap.overlaps_body(player):
			_trigger_trap_zap(trap)
			break

func _trigger_trap_zap(trap: Node2D) -> void:
	_trigger_glitch_hit(trap.global_position, "⚡ SegFault Glitch Surge! Cross the central grid when it is Stable (Cyan)!")

# ---------------------------------------------------------
# Prism Firewall Override Modal Logic
# ---------------------------------------------------------
func open_shrine_dialog(seal_id: String) -> void:
	if not SEALS_DATA.has(seal_id):
		return

	active_seal_id = seal_id
	current_seal_q_idx = 0
	seal_question_answered = false
	selected_option_idx = -1

	if player:
		player.can_move = false

	_render_current_seal_question()
	shrine_modal.visible = true
	shrine_modal_card.scale = Vector2(0.92, 0.92)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(shrine_modal_card, "scale", Vector2.ONE, 0.22)

func _render_current_seal_question() -> void:
	var data: Dictionary = SEALS_DATA[active_seal_id]
	var questions: Array = data.get("questions", [])
	var total_q: int = questions.size()
	var q_data: Dictionary = questions[current_seal_q_idx]
	var already_cleared: bool = active_seal_id in _get_unlocked_seals()

	seal_question_answered = false
	selected_option_idx = -1

	var pips_str = ""
	for i in range(total_q):
		if i < current_seal_q_idx:
			pips_str += "🟢 "
		elif i == current_seal_q_idx:
			pips_str += "🟡 "
		else:
			pips_str += "⚪ "

	shrine_modal_icon.text = data["icon"]
	shrine_modal_title.text = data["title"]
	shrine_modal_topic.text = "%s   |   Step %d of %d  [%s]" % [data["topic"], current_seal_q_idx + 1, total_q, pips_str.strip_edges()]
	shrine_lesson_text.text = data["lesson"]
	shrine_question_label.text = "[b]Firewall Override (%d/%d):[/b] %s" % [current_seal_q_idx + 1, total_q, q_data["question"]]

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
		shrine_feedback_label.text = "✅ Prism Already Overridden! Practicing Step %d/%d." % [current_seal_q_idx + 1, total_q]
		shrine_feedback_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.55))
	else:
		shrine_feedback_label.text = "Select the correct Python override to breach Step %d of %d." % [current_seal_q_idx + 1, total_q]
		shrine_feedback_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.95))

	shrine_action_btn.text = "⚡ Execute Override (%d/%d)" % [current_seal_q_idx + 1, total_q]
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
	box.set_border_width_all(2)

	if is_correct:
		box.bg_color = Color(0.1, 0.35, 0.22, 0.95)
		box.border_color = Color(0.25, 0.95, 0.5, 1.0)
	elif is_wrong:
		box.bg_color = Color(0.38, 0.12, 0.15, 0.95)
		box.border_color = Color(0.95, 0.3, 0.35, 1.0)
	elif selected:
		box.bg_color = Color(0.24, 0.12, 0.36, 0.95)
		box.border_color = Color(0.98, 0.75, 0.25, 1.0)
	else:
		box.bg_color = Color(0.12, 0.08, 0.18, 0.9)
		box.border_color = Color(0.42, 0.25, 0.58, 0.8)

	btn.add_theme_stylebox_override("normal", box)
	btn.add_theme_stylebox_override("hover", box)
	btn.add_theme_stylebox_override("pressed", box)

func _on_select_shrine_option(idx: int) -> void:
	if seal_question_answered:
		return
	selected_option_idx = idx
	shrine_action_btn.disabled = false

	var children = shrine_options_container.get_children()
	for i in range(children.size()):
		var btn = children[i] as Button
		_style_option_btn(btn, i == idx, false, false)

func _on_shrine_action() -> void:
	if not SEALS_DATA.has(active_seal_id):
		return

	var data: Dictionary = SEALS_DATA[active_seal_id]
	var questions: Array = data.get("questions", [])
	var total_q: int = questions.size()

	if seal_question_answered:
		if current_seal_q_idx + 1 < total_q:
			current_seal_q_idx += 1
			_render_current_seal_question()
		else:
			_on_close_shrine_modal()
		return

	if selected_option_idx < 0:
		return

	var q_data: Dictionary = questions[current_seal_q_idx]
	var correct_idx: int = q_data["correct_index"]
	var children = shrine_options_container.get_children()

	if selected_option_idx == correct_idx:
		seal_question_answered = true
		_style_option_btn(children[selected_option_idx] as Button, true, true, false)

		if current_seal_q_idx + 1 < total_q:
			AudioManager.play_sfx()
			shrine_feedback_label.text = "✅ Correct! %s" % q_data["explanation"]
			shrine_feedback_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
			shrine_action_btn.text = "Next Override Step (%d/%d) ➔" % [current_seal_q_idx + 2, total_q]
		else:
			var reward_xp: int = data.get("xp", 200)
			AudioManager.play_bridge_extend()
			var unlocked = _get_unlocked_seals()
			if not (active_seal_id in unlocked):
				unlocked.append(active_seal_id)
				SaveManager.user_profile["w6_prisms"] = unlocked
				SaveManager.user_profile["xp"] = int(SaveManager.user_profile.get("xp", 0)) + reward_xp
				SaveManager.save_local_profile()
				BadgeManager.check_all_badges()
				shrine_feedback_label.text = "🔓 %s Overridden! (+%d XP) %s" % [data["title"], reward_xp, q_data["explanation"]]
				show_toast("⚡ %s Overridden! General Field Aura Activated! (+%d XP)" % [data["title"], reward_xp])
			else:
				shrine_feedback_label.text = "🔓 %s Verified! %s" % [data["title"], q_data["explanation"]]
			shrine_feedback_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
			shrine_action_btn.text = "Return to Citadel Siege ✨"
			_refresh_all_seal_states()
	else:
		AudioManager.play_error()
		_style_option_btn(children[selected_option_idx] as Button, false, false, true)
		shrine_feedback_label.text = "❌ Firewall Rejected! Review the General's briefing above and try another option."
		shrine_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.45))

func _on_close_shrine_modal() -> void:
	shrine_modal.visible = false
	if player:
		player.can_move = true

# ---------------------------------------------------------
# Allied NPCs & Lore Chests
# ---------------------------------------------------------
func _get_helped_npcs() -> Array:
	var list = SaveManager.user_profile.get("w6_npcs_helped", [])
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

	_update_dialog_speaker(data["icon"], data["name"], data.get("portrait", "res://assets/sprites/portraits/portrait_pywizard.png"))

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
			accept_btn.text = "✅ Blessing Claimed"
			accept_btn.disabled = false
	else:
		if accept_btn:
			accept_btn.text = "🎁 Claim +%d XP & +1 Hint" % data["xp"]
			accept_btn.disabled = false

	quest_dialog.visible = true
	AudioManager.play_npc_chat()

func show_lore_modal(title: String, body: String, xp: int) -> void:
	if player:
		player.can_move = false
	if joystick:
		joystick.visible = false

	if lore_title_label:
		lore_title_label.text = "👑 " + title
	if lore_text_label:
		lore_text_label.text = body
	if lore_xp_label:
		lore_xp_label.text = "+%d XP Claimed!" % xp

	if lore_modal:
		lore_modal.visible = true
		lore_card.scale = Vector2(0.92, 0.92)
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(lore_card, "scale", Vector2.ONE, 0.22)

	show_toast("👑 Found Royal Codex: %s (+%d XP!)" % [title, xp])

func _on_close_lore_modal() -> void:
	if lore_modal:
		lore_modal.visible = false
	if player:
		player.can_move = true
	if joystick:
		joystick.visible = bool(SaveManager.get_setting("show_joystick", true))

# ---------------------------------------------------------
# Throne of Lord SegFault Showdown Dialog
# ---------------------------------------------------------
func open_quest_dialog() -> void:
	active_dialog_mode = "boss"
	if player:
		player.can_move = false

	var unlocked = _get_unlocked_seals()
	var count = unlocked.size()

	if not accept_btn:
		accept_btn = find_child("AcceptButton", true, false) as Button
	if not decline_btn:
		decline_btn = find_child("DeclineButton", true, false) as Button

	if count >= 4:
		_update_dialog_speaker("👑", "Lord SegFault • The Null Sovereign", "res://assets/sprites/portraits/portrait_segfault.png")
		if quest_text:
			quest_text.text = "ALL 4 PRISM TERMINALS ARE SHATTERED!\n\nLord SegFault's invincibility barrier collapses around Princess Ada's cage! All 5 Awakened Boss Generals (NullByte, Chronos-If, Lambda-Prime, Vektor-Zero, and Ignis-Py) lock their Assist Skills onto your Battle HUD!\n\nConfront LORD SEGFAULT (600 HP — 6-Phase Grand Finale) to free Princess Ada and restore Pythonia!"
		if accept_btn:
			accept_btn.text = "⚡ Confront Lord SegFault!"
			accept_btn.disabled = false
		if decline_btn:
			decline_btn.text = "Prepare More"
	else:
		_update_dialog_speaker("🧙‍♂️", "Master PyWizard & The 5 Awakened Generals", "res://assets/sprites/portraits/portrait_pywizard.png")
		var missing: PackedStringArray = []
		for s_id in SEAL_ORDER:
			if not (s_id in unlocked):
				missing.append("• " + SEALS_DATA[s_id]["title"])

		if quest_text:
			quest_text.text = "Lord SegFault's Glitch Barrier protects the Royal Throne (%d/4 Prisms Breached)!\n\nDodge the live Glitch Beams on the central floor and help each of the 4 Generals override their corner Prism Terminal:\n%s" % [count, "\n".join(missing)]
		if accept_btn:
			if SaveManager.is_dev_mode():
				accept_btn.text = "🛠️ Dev: Bypass Prisms & Fight SegFault!"
				accept_btn.disabled = false
			else:
				accept_btn.text = "🔒 Barrier Active (%d/4 Prisms)" % count
				accept_btn.disabled = true
		if decline_btn:
			decline_btn.text = "Back to Siege"

	quest_dialog.visible = true
	AudioManager.play_npc_chat()

func _on_accept_quest() -> void:
	if active_dialog_mode != "boss":
		var npc_id = active_dialog_mode
		var helped = _get_helped_npcs()
		if not (npc_id in helped) and NPCS_DATA.has(npc_id):
			helped.append(npc_id)
			SaveManager.user_profile["w6_npcs_helped"] = helped
			var xp_gain: int = NPCS_DATA[npc_id]["xp"]
			SaveManager.user_profile["xp"] = int(SaveManager.user_profile.get("xp", 0)) + xp_gain
			SaveManager.user_profile["hint_tokens"] = int(SaveManager.user_profile.get("hint_tokens", 5)) + 1
			SaveManager.save_local_profile()
			BadgeManager.check_all_badges()
			_refresh_all_npc_states()
			show_toast("🎁 +%d XP & +1 Hint Token from %s!" % [xp_gain, NPCS_DATA[npc_id]["name"].split("•")[0].strip_edges()])
		_on_close_quest_dialog()
		return

	if _get_unlocked_seals().size() < 4 and not SaveManager.is_dev_mode():
		show_toast("🔒 Override all 4 Generals' Prism Terminals first!")
		return
	SaveManager.user_profile["current_level"] = 6
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
	SaveManager.user_profile["w6_prisms"] = ["prism_nullbyte", "prism_chronos", "prism_lambda", "prism_vektor"]
	_refresh_all_seal_states()
	if player:
		player.global_position = Vector2(1200, 320)
	show_toast("🛠️ Dev Mode: All 4 Citadel Prisms Overridden & Teleported to Lord SegFault's Throne!")

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
