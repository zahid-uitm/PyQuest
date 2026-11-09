# res://scripts/ui/LevelSelectUI.gd
extends Control

# Landmark coordinates aligned precisely with the hand-painted map artwork
const LEVELS_DATA = [
	{
		"level": 1,
		"name": "Variable Valley",
		"chapter": "CHAPTER 1",
		"topic": "Variables & Data Types",
		"desc": "Explore the lush valley of Pythonia. Meet Master PyWizard, unlock ancient rune chests, and master Python variable declarations and type casting.",
		"icon": "🌿",
		"pos": Vector2(250, 640),
		"color": Color("#10B981"),       # Emerald Green
		"color_dark": Color("#064E3B"),
		"color_light": Color("#6EE7B7"),
		"zone_title": "Emerald Forest Altar",
		"badge": "🌿 RUNIC SANCTUARY"
	},
	{
		"level": 2,
		"name": "Chamber of Conditions",
		"chapter": "CHAPTER 2",
		"topic": "Control Structures (if / loops)",
		"desc": "Cross treacherous chasms with collapsing bridges and dangerous traps. Write conditional checks and loops to guide Alex across safely.",
		"icon": "💎",
		"pos": Vector2(650, 390),
		"color": Color("#0284C7"),       # Lapis Blue / Sky
		"color_dark": Color("#0C4A6E"),
		"color_light": Color("#7DD3FC"),
		"zone_title": "Azure Canyon Bridge",
		"badge": "💎 CRYSTAL CHASM"
	},
	{
		"level": 3,
		"name": "Relic Vault",
		"chapter": "CHAPTER 3",
		"topic": "Functions & Modularity",
		"desc": "An ancient subterranean sanctuary of arcane knowledge. Harness reusable functions and parameters to break magical seals.",
		"icon": "🔮",
		"pos": Vector2(995, 490),
		"color": Color("#9333EA"),       # Arcane Purple
		"color_dark": Color("#581C87"),
		"color_light": Color("#D8B4FE"),
		"zone_title": "Floating Arcane Obelisk",
		"badge": "🔮 MYSTIC MONOLITH"
	},
	{
		"level": 4,
		"name": "The Catacombs",
		"chapter": "CHAPTER 4",
		"topic": "Lists & Sequences",
		"desc": "Navigate the winding underground crypts. Organize inventory matrices, search lists for hidden keys, and manipulate array elements.",
		"icon": "🏺",
		"pos": Vector2(1340, 340),
		"color": Color("#D97706"),       # Ancient Amber Gold
		"color_dark": Color("#78350F"),
		"color_light": Color("#FDE68A"),
		"zone_title": "Golden Sandstone Tomb",
		"badge": "🏺 DESERT CRYPT"
	},
	{
		"level": 5,
		"name": "The Guardian's Lair",
		"chapter": "CHAPTER 5",
		"topic": "Grand Synthesis & Final Raid",
		"desc": "Ascend the volcanic Obsidian Spire over molten lava, shatter the 4 Elemental Seals alongside the Council of Mentors, and challenge Ignis-Py in a 3-stage Final Boss Raid.",
		"icon": "🌋",
		"pos": Vector2(1645, 430),
		"color": Color("#DC2626"),       # Molten Ruby Crimson
		"color_dark": Color("#7F1D1D"),
		"color_light": Color("#FCA5A5"),
		"zone_title": "Molten Obsidian Citadel",
		"badge": "🌋 VOLCANIC SUMMIT"
	},
	{
		"level": 6,
		"name": "The Royal Citadel",
		"chapter": "FINAL CHAPTER",
		"topic": "Grandmaster Mastery • Lord SegFault",
		"desc": "Cross the ancient keystone bridge to the Royal Citadel of Pythonia. Confront the mastermind of corruption, Lord SegFault, shatter Princess Ada's glitch prism, and restore Pythonia!",
		"icon": "🏰",
		"pos": Vector2(2885, 500),
		"color": Color("#A855F7"),       # Arcane Obsidian Violet / Crimson
		"color_dark": Color("#581C87"),
		"color_light": Color("#E9D5FF"),
		"zone_title": "Throne of Lord SegFault",
		"badge": "👑 CITADEL SANCTUM"
	}
]

const PAGE_WIDTH: float = 1920.0
const PAGE2_BRIDGE_ENTRY: Vector2 = Vector2(2304, 712)

# Top Bar Nodes
@onready var back_button: Button = $HeaderPanel/Header/BackButton
@onready var progress_label: Label = $HeaderPanel/Header/ProgressLabel
@onready var stars_total_label: Label = $HeaderPanel/Header/StarsTotalLabel
@onready var badges_btn: Button = get_node_or_null("%BadgesButton")
@onready var badges_modal: Control = get_node_or_null("BadgesModal")

# Map Background & Canvas Nodes
@onready var background_page1: TextureRect = $Background
@onready var background_page2: TextureRect = get_node_or_null("BackgroundPage2")
@onready var map_canvas: Control = $MapArea/MapCanvas
@onready var biome_canvas: Control = $MapArea/MapCanvas/BiomeCanvas
@onready var path_drawer: Control = $MapArea/MapCanvas/PathDrawer
@onready var nodes_container: Control = $MapArea/MapCanvas/NodesContainer
@onready var fog_canvas: Control = get_node_or_null("MapArea/MapCanvas/FogCanvas")
@onready var alex_token_layer: Control = get_node_or_null("MapArea/MapCanvas/AlexTokenLayer")

# World Detail Modal
@onready var modal_overlay: ColorRect = $ModalOverlay
@onready var modal_icon: Label = $ModalOverlay/Center/Card/VBox/HeaderHBox/IconLabel
@onready var modal_chapter: Label = $ModalOverlay/Center/Card/VBox/HeaderHBox/TitleVBox/ChapterLabel
@onready var modal_title: Label = $ModalOverlay/Center/Card/VBox/HeaderHBox/TitleVBox/TitleLabel
@onready var modal_topic: Label = $ModalOverlay/Center/Card/VBox/HeaderHBox/TitleVBox/TopicLabel
@onready var modal_desc: Label = $ModalOverlay/Center/Card/VBox/DescLabel
@onready var modal_stars: Label = $ModalOverlay/Center/Card/VBox/StatsBox/StatsHBox/StarsValue
@onready var modal_status: Label = $ModalOverlay/Center/Card/VBox/StatsBox/StatsHBox/StatusValue
@onready var modal_close_btn: Button = $ModalOverlay/Center/Card/VBox/ButtonHBox/CloseButton
@onready var modal_travel_btn: Button = $ModalOverlay/Center/Card/VBox/ButtonHBox/TravelButton
var modal_intro_btn: Button = null

var selected_level_num: int = 1
var current_map_page: int = 0
var page_slide_tween: Tween = null
var prev_page_btn: Button = null
var next_page_btn: Button = null
var alex_token: Control = null
var token_visuals: Control = null
var alex_bob_tween: Tween = null
var alex_current_pos: Vector2 = Vector2.ZERO
var is_alex_hopping: bool = false
var energy_pulse_t: float = 0.0

func _ready() -> void:
	AudioManager.play_bgm_by_path("res://assets/audio/mainmenu_music.mp3", 0.01)
	modal_overlay.visible = false
	back_button.pressed.connect(_on_back_button_pressed)
	modal_close_btn.pressed.connect(_on_close_modal)
	modal_travel_btn.pressed.connect(_on_confirm_travel)

	_setup_page_nav_buttons()

	# Prologue Story Cinematic button for Chapter 1
	modal_intro_btn = Button.new()
	modal_intro_btn.text = "🎬 Watch Prologue"
	modal_intro_btn.custom_minimum_size = Vector2(170, 48)
	modal_intro_btn.focus_mode = Control.FOCUS_NONE
	var style_intro = StyleBoxFlat.new()
	style_intro.bg_color = Color("#1E293B")
	style_intro.border_color = Color("#38BDF8")
	style_intro.set_border_width_all(2)
	style_intro.set_corner_radius_all(8)
	modal_intro_btn.add_theme_stylebox_override("normal", style_intro)
	var style_intro_hov = style_intro.duplicate() as StyleBoxFlat
	style_intro_hov.bg_color = Color("#0369A1")
	style_intro_hov.border_color = Color("#7DD3FC")
	modal_intro_btn.add_theme_stylebox_override("hover", style_intro_hov)
	modal_intro_btn.add_theme_color_override("font_color", Color("#BAE6FD"))
	modal_intro_btn.pressed.connect(func():
		if selected_level_num == 6:
			SceneManager.change_scene(SceneManager.CUTSCENE_THRONE)
		elif selected_level_num == 5:
			SceneManager.change_scene(SceneManager.CUTSCENE_PLOT_TWIST)
		else:
			SceneManager.change_scene(SceneManager.CINEMATIC_INTRO)
	)
	var btn_box = $ModalOverlay/Center/Card/VBox/ButtonHBox
	btn_box.add_child(modal_intro_btn)
	btn_box.move_child(modal_intro_btn, 1)

	if badges_btn:
		badges_btn.pressed.connect(func():
			if badges_modal and badges_modal.has_method("open_modal"):
				badges_modal.open_modal()
		)
		var unl = BadgeManager.get_unlocked_count()
		var tot = BadgeManager.get_total_badges()
		badges_btn.text = "🏆 Badges: %d/%d" % [unl, tot]

	path_drawer.draw.connect(_on_draw_saga_road)
	if SaveManager.has_signal("dev_mode_changed"):
		SaveManager.dev_mode_changed.connect(func(_enabled: bool):
			build_map()
			if modal_overlay and modal_overlay.visible:
				_open_level_modal(selected_level_num)
		)

	var is_unsealing_castle: bool = bool(SaveManager.user_profile.get("just_unlocked_castle", false))
	var cur_lvl: int = int(SaveManager.user_profile.get("current_level", 1))
	var real_unl: int = int(SaveManager.user_profile.get("unlocked_level", 1))
	var can_view_page2: bool = (real_unl >= 6 or SaveManager.is_dev_mode())

	if is_unsealing_castle:
		_slide_to_page(0, false)
	elif cur_lvl == 6 and can_view_page2 and SaveManager.pending_map_advance_to == 0:
		_slide_to_page(1, false)
	else:
		_slide_to_page(0, false)

	build_map()

	if SaveManager.pending_map_advance_to > 0:
		var target_next: int = SaveManager.pending_map_advance_to
		SaveManager.pending_map_advance_to = 0
		SaveManager.user_profile["current_level"] = target_next
		SaveManager.save_local_profile()
		call_deferred("_auto_advance_to_next_world", target_next)
	elif is_unsealing_castle:
		SaveManager.user_profile["just_unlocked_castle"] = false
		SaveManager.save_local_profile()
		call_deferred("_play_castle_unseal_animation")

func _setup_page_nav_buttons() -> void:
	var nav_style := StyleBoxFlat.new()
	nav_style.bg_color = Color(0.18, 0.10, 0.06, 0.95)
	nav_style.border_color = Color("#FBBF24")
	nav_style.set_border_width_all(2)
	nav_style.border_width_bottom = 4
	nav_style.set_corner_radius_all(12)
	nav_style.content_margin_left = 18.0
	nav_style.content_margin_right = 18.0
	nav_style.content_margin_top = 12.0
	nav_style.content_margin_bottom = 12.0
	nav_style.shadow_color = Color(0, 0, 0, 0.75)
	nav_style.shadow_size = 10
	nav_style.shadow_offset = Vector2(0, 4)

	var nav_hover := nav_style.duplicate() as StyleBoxFlat
	nav_hover.bg_color = Color(0.32, 0.18, 0.10, 0.98)
	nav_hover.border_color = Color("#FEF08A")

	prev_page_btn = Button.new()
	prev_page_btn.text = "⬅ Worlds 1–5"
	prev_page_btn.focus_mode = Control.FOCUS_NONE
	prev_page_btn.position = Vector2(28, 520)
	prev_page_btn.custom_minimum_size = Vector2(180, 52)
	prev_page_btn.add_theme_font_size_override("font_size", 16)
	prev_page_btn.add_theme_color_override("font_color", Color("#FEF08A"))
	prev_page_btn.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	prev_page_btn.add_theme_stylebox_override("normal", nav_style)
	prev_page_btn.add_theme_stylebox_override("hover", nav_hover)
	prev_page_btn.add_theme_stylebox_override("pressed", nav_style)
	prev_page_btn.pressed.connect(func():
		_slide_to_page(0, true)
	)
	add_child(prev_page_btn)
	move_child(prev_page_btn, get_child_count() - 2)

	next_page_btn = Button.new()
	next_page_btn.text = "🏰 Royal Citadel ➡"
	next_page_btn.focus_mode = Control.FOCUS_NONE
	next_page_btn.position = Vector2(1688, 520)
	next_page_btn.custom_minimum_size = Vector2(204, 52)
	next_page_btn.add_theme_font_size_override("font_size", 16)
	next_page_btn.add_theme_color_override("font_color", Color("#E9D5FF"))
	next_page_btn.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	var next_style := nav_style.duplicate() as StyleBoxFlat
	next_style.bg_color = Color(0.22, 0.10, 0.34, 0.95)
	next_style.border_color = Color("#C084FC")
	var next_hover := nav_hover.duplicate() as StyleBoxFlat
	next_hover.bg_color = Color(0.35, 0.16, 0.52, 0.98)
	next_hover.border_color = Color("#F3E8FF")
	next_page_btn.add_theme_stylebox_override("normal", next_style)
	next_page_btn.add_theme_stylebox_override("hover", next_hover)
	next_page_btn.add_theme_stylebox_override("pressed", next_style)
	next_page_btn.pressed.connect(func():
		_slide_to_page(1, true)
	)
	add_child(next_page_btn)
	move_child(next_page_btn, get_child_count() - 2)

	_update_page_nav_buttons()

func _update_page_nav_buttons() -> void:
	var real_unlocked: int = int(SaveManager.user_profile.get("unlocked_level", 1))
	var show_castle: bool = (real_unlocked >= 6 or SaveManager.is_dev_mode())
	if prev_page_btn:
		prev_page_btn.visible = (current_map_page == 1)
	if next_page_btn:
		next_page_btn.visible = (current_map_page == 0 and show_castle)

func _slide_to_page(page_idx: int, animated: bool = true) -> void:
	current_map_page = clampi(page_idx, 0, 1)
	_update_page_nav_buttons()

	var target_x: float = -float(current_map_page) * PAGE_WIDTH
	var target_bg2_x: float = target_x + PAGE_WIDTH

	if page_slide_tween and page_slide_tween.is_valid():
		page_slide_tween.kill()

	if not animated:
		if background_page1:
			background_page1.position.x = target_x
		if background_page2:
			background_page2.position.x = target_bg2_x
		if map_canvas:
			map_canvas.position.x = target_x
		return

	page_slide_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if background_page1:
		page_slide_tween.tween_property(background_page1, "position:x", target_x, 1.05)
	if background_page2:
		page_slide_tween.tween_property(background_page2, "position:x", target_bg2_x, 1.05)
	if map_canvas:
		page_slide_tween.tween_property(map_canvas, "position:x", target_x, 1.05)
	await page_slide_tween.finished

func _auto_advance_to_next_world(target_next: int) -> void:
	await get_tree().create_timer(0.4).timeout
	if is_inside_tree():
		_hop_alex_to_level(target_next)

func _play_castle_unseal_animation() -> void:
	# 1. Start on Page 1 with Alex at World 5
	_slide_to_page(0, false)
	_spawn_alex_token(5)
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree(): return

	# 2. Dramatic screen tremor & bridge unseal sounds
	AudioManager.play_sfx(AudioManager.SFX_SHRINE_AWAKEN)
	_shake_map(8.0, 0.95)
	AudioManager.play_bridge_extend()
	await get_tree().create_timer(0.95).timeout
	if not is_inside_tree(): return

	# 3. Rebuild map to reveal World 6 on Page 2 (initially scaled to zero for pop-in)
	build_map()
	_spawn_alex_token(5)

	var w6_pos: Vector2 = LEVELS_DATA[5]["pos"] - Vector2(40, 40)
	var w6_node: Control = null
	for child in nodes_container.get_children():
		if child is Control and child.position.distance_to(w6_pos) < 5.0:
			w6_node = child
			w6_node.scale = Vector2.ZERO
			break

	# 4. Smoothly pan/slide the screen to the next map page on the right!
	await _slide_to_page(1, true)
	if not is_inside_tree(): return

	# 5. Animate dramatic pop-in of the Castle node in the center of Page 2
	if w6_node and is_instance_valid(w6_node):
		AudioManager.play_sfx(AudioManager.SFX_BADGE_UNLOCK)
		var pop_tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tw.tween_property(w6_node, "scale", Vector2(1.3, 1.3), 0.45)
		pop_tw.tween_property(w6_node, "scale", Vector2.ONE, 0.2)
		await pop_tw.finished

	await get_tree().create_timer(0.35).timeout
	if is_inside_tree():
		# 6. Place Alex at the stone bridge entrance on Page 2 and hop to the Castle!
		if alex_token and is_instance_valid(alex_token):
			alex_token.position = PAGE2_BRIDGE_ENTRY - Vector2(24, 78)
			alex_current_pos = PAGE2_BRIDGE_ENTRY
		_hop_alex_to_level(6)

func _shake_map(intensity: float, duration: float) -> void:
	if not map_canvas: return
	var base_pos := Vector2(-float(current_map_page) * PAGE_WIDTH, 0.0)
	var tw = create_tween()
	var steps: int = int(duration / 0.05)
	for i in range(steps):
		var damp: float = 1.0 - (float(i) / float(steps))
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)) * damp
		tw.tween_property(map_canvas, "position", base_pos + offset, 0.05)
	tw.tween_property(map_canvas, "position", base_pos, 0.05)

func _process(delta: float) -> void:
	energy_pulse_t = fmod(energy_pulse_t + delta * 0.4, 1.0)
	if path_drawer:
		path_drawer.queue_redraw()

func _get_stars_dict() -> Dictionary:
	var raw_stars = SaveManager.user_profile.get("level_stars", {})
	var converted: Dictionary = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0, "6": 0}
	if typeof(raw_stars) == TYPE_DICTIONARY:
		for k in raw_stars.keys():
			var v = raw_stars[k]
			if v != null and (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT):
				converted[str(k)] = int(v)
	elif typeof(raw_stars) == TYPE_ARRAY:
		var arr: Array = raw_stars
		var is_one_indexed: bool = arr.size() > 0 and arr[0] == null
		for idx in range(arr.size()):
			var item = arr[idx]
			if item != null and (typeof(item) == TYPE_INT or typeof(item) == TYPE_FLOAT):
				var lvl_key = str(idx) if is_one_indexed else str(idx + 1)
				converted[lvl_key] = int(item)
	return converted

func build_map() -> void:
	for child in nodes_container.get_children():
		child.queue_free()

	if alex_token_layer:
		for child in alex_token_layer.get_children():
			child.queue_free()

	var real_unlocked: int = int(SaveManager.user_profile.get("unlocked_level", 1))
	var unlocked_level: int = 6 if SaveManager.is_dev_mode() else real_unlocked
	var current_level: int = int(SaveManager.user_profile.get("current_level", 1))
	if current_level > unlocked_level:
		current_level = unlocked_level
	var stars_dict: Dictionary = _get_stars_dict()

	var total_stars: int = 0
	for k in stars_dict.keys():
		total_stars += int(stars_dict[k])

	if unlocked_level >= 6 or SaveManager.is_dev_mode():
		progress_label.text = "Chapter %d of 6 • The Final Citadel" % min(unlocked_level, 6)
		stars_total_label.text = "⭐ %d / 18 Stars" % total_stars
	else:
		progress_label.text = "World %d of 5" % min(unlocked_level, 5)
		stars_total_label.text = "⭐ %d / 15 Stars" % total_stars

	for info in LEVELS_DATA:
		var lvl: int = info["level"]
		# World 6 stays completely hidden until World 5 is conquered!
		if lvl == 6 and unlocked_level < 6 and not SaveManager.is_dev_mode():
			continue

		var is_unlocked: bool = lvl <= unlocked_level
		var is_current: bool = (lvl == current_level)
		var star_count: int = int(stars_dict.get(str(lvl), 0))

		var node_btn = _create_tactile_landmark_node(info, is_unlocked, is_current, star_count)
		node_btn.position = info["pos"] - Vector2(40, 40)
		nodes_container.add_child(node_btn)

	_spawn_alex_token(current_level)

	if current_map_page == 1 and unlocked_level < 6 and not SaveManager.is_dev_mode():
		_slide_to_page(0, true)
	else:
		_update_page_nav_buttons()

	path_drawer.queue_redraw()

# -------------------------------------------------------------
# ALEX LIVING CHARACTER TOKEN
# -------------------------------------------------------------
func _spawn_alex_token(level_num: int) -> void:
	if not alex_token_layer:
		return

	if alex_bob_tween and alex_bob_tween.is_valid():
		alex_bob_tween.kill()

	var info: Dictionary = LEVELS_DATA[level_num - 1]
	alex_current_pos = info["pos"]

	alex_token = Control.new()
	alex_token.size = Vector2(48, 64)
	alex_token.position = alex_current_pos - Vector2(24, 78)
	alex_token.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Inner visual container for local bobbing and landing squash/stretch
	token_visuals = Control.new()
	token_visuals.size = Vector2(48, 64)
	token_visuals.position = Vector2.ZERO
	token_visuals.pivot_offset = Vector2(24, 56) # Pivot near character feet
	token_visuals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alex_token.add_child(token_visuals)

	# Sprite Container
	var sprite_rect = TextureRect.new()
	sprite_rect.size = Vector2(48, 48)
	sprite_rect.position = Vector2(0, 16)
	sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var player_sheet = load("res://assets/sprites/characters/player.png")
	if player_sheet:
		var atlas = AtlasTexture.new()
		atlas.atlas = player_sheet
		atlas.region = Rect2(0, 0, 48, 48)
		sprite_rect.texture = atlas

	token_visuals.add_child(sprite_rect)

	# "ALEX" Pointer Placard
	var pin_panel = PanelContainer.new()
	pin_panel.position = Vector2(-16, -10)
	pin_panel.size = Vector2(80, 22)
	pin_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pin_style = StyleBoxFlat.new()
	pin_style.bg_color = Color("#854D0E")
	pin_style.border_color = Color("#FDE047")
	pin_style.set_border_width_all(2)
	pin_style.set_corner_radius_all(6)
	pin_style.shadow_color = Color(0, 0, 0, 0.7)
	pin_style.shadow_size = 4
	pin_style.shadow_offset = Vector2(0, 2)
	pin_panel.add_theme_stylebox_override("panel", pin_style)

	var pin_tag = Label.new()
	pin_tag.text = "📍 ALEX"
	pin_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pin_tag.add_theme_font_size_override("font_size", 10)
	pin_tag.add_theme_color_override("font_color", Color("#FEF08A"))
	pin_tag.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	pin_tag.add_theme_constant_override("shadow_offset_y", 1)
	pin_panel.add_child(pin_tag)
	token_visuals.add_child(pin_panel)

	alex_token_layer.add_child(alex_token)

	_start_alex_bob()

func _start_alex_bob() -> void:
	if not token_visuals:
		return
	if alex_bob_tween and alex_bob_tween.is_valid():
		alex_bob_tween.kill()
	token_visuals.position.y = 0.0
	alex_bob_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	alex_bob_tween.tween_property(token_visuals, "position:y", -5.0, 1.1)
	alex_bob_tween.tween_property(token_visuals, "position:y", 0.0, 1.1)

func _hop_alex_to_level(target_level_num: int) -> void:
	if not alex_token or is_alex_hopping:
		_open_level_modal(target_level_num)
		return

	var target_page: int = 1 if target_level_num == 6 else 0
	if current_map_page != target_page:
		await _slide_to_page(target_page, true)
		if not is_inside_tree() or not alex_token:
			return
		if target_page == 1 and alex_token.position.x < PAGE_WIDTH:
			alex_token.position = PAGE2_BRIDGE_ENTRY - Vector2(24, 78)
			alex_current_pos = PAGE2_BRIDGE_ENTRY
		elif target_page == 0 and alex_token.position.x >= PAGE_WIDTH:
			var w5_pos: Vector2 = LEVELS_DATA[4]["pos"]
			alex_token.position = w5_pos - Vector2(24, 78)
			alex_current_pos = w5_pos

	var target_info: Dictionary = LEVELS_DATA[target_level_num - 1]
	var target_pos: Vector2 = target_info["pos"] - Vector2(24, 78)

	if alex_token.position.distance_to(target_pos) < 15.0:
		_open_level_modal(target_level_num)
		return

	is_alex_hopping = true

	# Stop bobbing while mid-air
	if alex_bob_tween and alex_bob_tween.is_valid():
		alex_bob_tween.kill()
	if token_visuals:
		token_visuals.position.y = 0.0

	var start_pos: Vector2 = alex_token.position
	var mid_x: float = (start_pos.x + target_pos.x) * 0.5
	var peak_y: float = min(start_pos.y, target_pos.y) - 65.0
	var hop_half_time: float = 0.28

	var hop_tween = create_tween()
	# Upward arc to apex
	hop_tween.set_parallel(true)
	hop_tween.tween_property(alex_token, "position:x", mid_x, hop_half_time).set_trans(Tween.TRANS_LINEAR)
	hop_tween.tween_property(alex_token, "position:y", peak_y, hop_half_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Downward arc from apex directly to target destination
	hop_tween.chain().tween_property(alex_token, "position:x", target_pos.x, hop_half_time).set_trans(Tween.TRANS_LINEAR)
	hop_tween.parallel().tween_property(alex_token, "position:y", target_pos.y, hop_half_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await hop_tween.finished
	alex_token.position = target_pos # Lock exact destination coordinate
	alex_current_pos = target_info["pos"]
	is_alex_hopping = false

	# Squash & stretch bounce upon landing
	if token_visuals:
		var land_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		land_tween.tween_property(token_visuals, "scale", Vector2(1.25, 0.75), 0.08)
		land_tween.tween_property(token_visuals, "scale", Vector2(1.0, 1.0), 0.14)
		await land_tween.finished

	# Resume gentle bobbing at the new landmark
	_start_alex_bob()

	_open_level_modal(target_level_num)

# -------------------------------------------------------------
# DRAWING VINTAGE FANTASY MAP EXPEDITION DASHED TRAIL
# -------------------------------------------------------------
func _on_draw_saga_road() -> void:
	var unlocked_level: int = 6 if SaveManager.is_dev_mode() else int(SaveManager.user_profile.get("unlocked_level", 1))
	var show_castle: bool = (unlocked_level >= 6 or SaveManager.is_dev_mode())
	var page1_segments: int = 4 # Worlds 1 -> 2 -> 3 -> 4 -> 5 on Page 1

	var p0: Vector2
	var p3: Vector2
	var mid_x: float
	var p1: Vector2
	var p2: Vector2

	var full_curve_points: Array[Vector2] = []
	for i in range(page1_segments):
		p0 = LEVELS_DATA[i]["pos"]
		p3 = LEVELS_DATA[i + 1]["pos"]
		mid_x = (p0.x + p3.x) * 0.5
		p1 = Vector2(mid_x, p0.y)
		p2 = Vector2(mid_x, p3.y)

		var seg_points = _sample_cubic_bezier(p0, p1, p2, p3, 28)
		if i > 0 and seg_points.size() > 0:
			seg_points.remove_at(0)
		full_curve_points.append_array(seg_points)

	if full_curve_points.size() < 2:
		return

	# Draw Page 1 segments connecting Worlds 1 to 5
	for i in range(page1_segments):
		p0 = LEVELS_DATA[i]["pos"]
		p3 = LEVELS_DATA[i + 1]["pos"]
		mid_x = (p0.x + p3.x) * 0.5
		p1 = Vector2(mid_x, p0.y)
		p2 = Vector2(mid_x, p3.y)
		var seg = _sample_cubic_bezier(p0, p1, p2, p3, 28)

		var is_seg_unlocked = (i + 1) < unlocked_level

		# 1. Soft ink shadow
		var shadow_col = Color(0.15, 0.08, 0.04, 0.45)
		var shadow_seg: Array[Vector2] = []
		for pt in seg:
			shadow_seg.append(pt + Vector2(0, 3))
		_draw_dashed_curve(path_drawer, shadow_seg, shadow_col, 6.0, 10.0, 8.0)

		# 2. Inked expedition dashed trail
		if is_seg_unlocked:
			_draw_dashed_curve(path_drawer, seg, Color("#B45309"), 5.0, 10.0, 8.0)
			_draw_dashed_curve(path_drawer, seg, Color("#FDE047"), 3.0, 8.0, 10.0)
		else:
			_draw_dashed_curve(path_drawer, seg, Color(0.35, 0.22, 0.12, 0.75), 4.0, 8.0, 10.0)

	# Draw Page 2 Keystone Causeway trail into the Royal Citadel (plus Page 1 eastern bridge departure)
	if show_castle:
		var w5_pos: Vector2 = LEVELS_DATA[4]["pos"]
		var page1_east_edge := Vector2(1865, 515)
		var east_seg := _sample_cubic_bezier(w5_pos, Vector2(1740, 445), Vector2(1810, 495), page1_east_edge, 16)
		var shadow_east: Array[Vector2] = []
		for pt in east_seg:
			shadow_east.append(pt + Vector2(0, 3))
		_draw_dashed_curve(path_drawer, shadow_east, Color(0.15, 0.08, 0.04, 0.45), 6.0, 10.0, 8.0)
		_draw_dashed_curve(path_drawer, east_seg, Color("#7E22CE"), 7.0, 12.0, 6.0)
		_draw_dashed_curve(path_drawer, east_seg, Color("#EC4899"), 5.0, 10.0, 8.0)
		_draw_dashed_curve(path_drawer, east_seg, Color("#FDE047"), 3.0, 6.0, 10.0)

		var castle_pos: Vector2 = LEVELS_DATA[5]["pos"]
		var bridge_seg := _sample_cubic_bezier(
			PAGE2_BRIDGE_ENTRY,
			Vector2(2520, 600),
			Vector2(2710, 560),
			castle_pos,
			28
		)
		var shadow_bridge: Array[Vector2] = []
		for pt in bridge_seg:
			shadow_bridge.append(pt + Vector2(0, 3))
		_draw_dashed_curve(path_drawer, shadow_bridge, Color(0.15, 0.08, 0.04, 0.45), 6.0, 10.0, 8.0)
		_draw_dashed_curve(path_drawer, bridge_seg, Color("#7E22CE"), 7.0, 12.0, 6.0)
		_draw_dashed_curve(path_drawer, bridge_seg, Color("#EC4899"), 5.0, 10.0, 8.0)
		_draw_dashed_curve(path_drawer, bridge_seg, Color("#FDE047"), 3.0, 6.0, 10.0)

		var pulse_idx: int = int(energy_pulse_t * float(bridge_seg.size() - 1))
		var bridge_pulse_pt: Vector2 = bridge_seg[clampi(pulse_idx, 0, bridge_seg.size() - 1)]
		path_drawer.draw_circle(bridge_pulse_pt, 8.0, Color(0.9, 0.4, 1.0, 0.65))
		path_drawer.draw_circle(bridge_pulse_pt, 4.0, Color(1.0, 0.95, 0.7, 0.95))

	# 3. Animated glowing magical energy mote traveling along the Page 1 unlocked road
	if unlocked_level > 1 and full_curve_points.size() > 10:
		var max_seg_idx = min(unlocked_level - 1, page1_segments)
		var unlocked_pts_count = int(float(full_curve_points.size()) * (float(max_seg_idx) / float(page1_segments)))
		if unlocked_pts_count > 2:
			var target_idx = int(energy_pulse_t * float(unlocked_pts_count - 1))
			var pulse_pt = full_curve_points[clamp(target_idx, 0, unlocked_pts_count - 1)]
			var spark_col = Color(1.0, 0.85, 0.25, 0.45)
			path_drawer.draw_circle(pulse_pt, 8.0, spark_col)
			path_drawer.draw_circle(pulse_pt, 4.0, Color(1.0, 0.95, 0.7, 0.95))

func _sample_cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, steps: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for s in range(steps + 1):
		var t = float(s) / float(steps)
		var omt = 1.0 - t
		var pt = omt * omt * omt * p0 + 3.0 * omt * omt * t * p1 + 3.0 * omt * t * t * p2 + t * t * t * p3
		points.append(pt)
	return points

func _draw_dashed_curve(canvas: Control, points: Array[Vector2], color: Color, width: float, dash_len: float, gap_len: float) -> void:
	if points.size() < 2:
		return
	var is_drawing = true
	var cur_len = 0.0
	for i in range(points.size() - 1):
		var seg_start = points[i]
		var seg_end = points[i + 1]
		var seg_dist = seg_start.distance_to(seg_end)
		if is_drawing:
			canvas.draw_line(seg_start, seg_end, color, width)
		cur_len += seg_dist
		if is_drawing and cur_len >= dash_len:
			is_drawing = false
			cur_len = 0.0
		elif not is_drawing and cur_len >= gap_len:
			is_drawing = true
			cur_len = 0.0

# -------------------------------------------------------------
# TACTILE MEDALLION LANDMARK BUTTONS (PVZ / KINGDOM RUSH STYLE)
# -------------------------------------------------------------
func _create_tactile_landmark_node(info: Dictionary, is_unlocked: bool, _is_current: bool, star_count: int) -> Control:
	var root = Control.new()
	root.custom_minimum_size = Vector2(80, 80)
	root.size = Vector2(80, 80)
	root.pivot_offset = Vector2(40, 40)

	# --- 1. Arch of 3 Stars on top ---
	var stars_control = Control.new()
	stars_control.size = Vector2(80, 32)
	stars_control.position = Vector2(0, -32)
	stars_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stars_control)

	var star_offsets = [
		{"pos": Vector2(8, 8),  "rot": -0.25, "scale": 0.9, "idx": 0},
		{"pos": Vector2(30, -2), "rot": 0.0,   "scale": 1.2, "idx": 1},
		{"pos": Vector2(52, 8),  "rot": 0.25,  "scale": 0.9, "idx": 2}
	]

	for st in star_offsets:
		var s_lbl = Label.new()
		var earned = is_unlocked and (st["idx"] < star_count)
		s_lbl.text = "★"
		s_lbl.position = st["pos"]
		s_lbl.rotation = st["rot"]
		s_lbl.scale = Vector2(st["scale"], st["scale"])
		s_lbl.add_theme_font_size_override("font_size", 20)
		if earned:
			s_lbl.add_theme_color_override("font_color", Color("#FBBF24"))
			s_lbl.add_theme_color_override("font_shadow_color", Color("#B45309"))
			s_lbl.add_theme_constant_override("shadow_offset_y", 2)
		else:
			s_lbl.add_theme_color_override("font_color", Color("#475569") if is_unlocked else Color("#334155"))
			s_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		stars_control.add_child(s_lbl)

	# --- 2. 3D Medallion Button ---
	var btn = Button.new()
	btn.position = Vector2(0, 0)
	btn.size = Vector2(80, 80)
	btn.custom_minimum_size = Vector2(80, 80)
	btn.focus_mode = Control.FOCUS_NONE

	var theme_col: Color = info["color"]
	var _theme_dark: Color = info["color_dark"]
	var theme_light: Color = info["color_light"]

	var style_normal = StyleBoxFlat.new()
	style_normal.corner_radius_top_left = 40
	style_normal.corner_radius_top_right = 40
	style_normal.corner_radius_bottom_right = 40
	style_normal.corner_radius_bottom_left = 40
	style_normal.set_border_width_all(4)

	if is_unlocked:
		style_normal.bg_color = theme_col
		style_normal.border_color = Color("#FEF08A")
		style_normal.shadow_color = Color(0, 0, 0, 0.75)
		style_normal.shadow_size = 10
		style_normal.shadow_offset = Vector2(0, 6)
		if info["level"] == 6:
			btn.text = "🏰"
			btn.add_theme_font_size_override("font_size", 38)
		else:
			btn.text = str(info["level"])
			btn.add_theme_font_size_override("font_size", 34)
		btn.add_theme_color_override("font_color", Color("#FFFFFF"))
		btn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		btn.add_theme_constant_override("shadow_offset_y", 2)
	else:
		style_normal.bg_color = Color("#292524") # Dark antique slate
		style_normal.border_color = Color("#78716C")
		style_normal.shadow_color = Color(0, 0, 0, 0.6)
		style_normal.shadow_size = 6
		style_normal.shadow_offset = Vector2(0, 4)
		btn.text = "🔒"
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_color_override("font_color", Color("#A8A29E"))

	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = style_normal.duplicate() as StyleBoxFlat
	if is_unlocked:
		style_hover.bg_color = theme_light
		style_hover.shadow_size = 14
		style_hover.shadow_offset = Vector2(0, 8)
	btn.add_theme_stylebox_override("hover", style_hover)

	btn.mouse_entered.connect(func():
		var tw_hover = root.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_hover.tween_property(root, "scale", Vector2(1.15, 1.15), 0.2)
	)
	btn.mouse_exited.connect(func():
		var tw_exit = root.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw_exit.tween_property(root, "scale", Vector2(1.0, 1.0), 0.22)
	)

	btn.pressed.connect(func():
		if is_unlocked:
			_hop_alex_to_level(info["level"])
		else:
			_open_level_modal(info["level"])
	)
	root.add_child(btn)

	# --- 3. Parchment Ribbon Title Underneath ---
	var ribbon = PanelContainer.new()
	ribbon.position = Vector2(-35, 86)
	ribbon.size = Vector2(150, 24)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ribbon_style = StyleBoxFlat.new()
	ribbon_style.bg_color = Color(0.18, 0.11, 0.06, 0.92)
	ribbon_style.border_color = Color("#B45309") if is_unlocked else Color("#57534E")
	ribbon_style.set_border_width_all(1)
	ribbon_style.set_corner_radius_all(5)
	ribbon_style.shadow_color = Color(0, 0, 0, 0.5)
	ribbon_style.shadow_size = 3
	ribbon_style.shadow_offset = Vector2(0, 2)
	ribbon.add_theme_stylebox_override("panel", ribbon_style)

	var ribbon_label = Label.new()
	ribbon_label.text = info["name"]
	ribbon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon_label.add_theme_font_size_override("font_size", 11)
	ribbon_label.add_theme_color_override("font_color", Color("#FEF08A") if is_unlocked else Color("#A8A29E"))
	ribbon_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	ribbon_label.add_theme_constant_override("shadow_offset_y", 1)
	ribbon.add_child(ribbon_label)

	root.add_child(ribbon)

	return root

# -------------------------------------------------------------
# MODAL OVERLAY & TRAVEL HANDLERS
# -------------------------------------------------------------
func _open_level_modal(level_num: int) -> void:
	selected_level_num = level_num
	var info: Dictionary = LEVELS_DATA[level_num - 1]
	var real_unlocked: int = int(SaveManager.user_profile.get("unlocked_level", 1))
	var unlocked_level: int = 6 if SaveManager.is_dev_mode() else real_unlocked
	var stars_dict: Dictionary = _get_stars_dict()
	var is_unlocked: bool = level_num <= unlocked_level
	var star_count: int = int(stars_dict.get(str(level_num), 0))

	modal_icon.text = info["icon"]
	modal_chapter.text = info["chapter"]
	modal_title.text = info["name"]
	modal_topic.text = "Core Subject: %s" % info["topic"]
	modal_desc.text = info["desc"]

	var stars_str = ""
	for s in range(3):
		stars_str += "★" if s < star_count else "☆"
	modal_stars.text = "%s (%d / 3 Stars)" % [stars_str, star_count]

	if is_unlocked:
		if level_num > real_unlocked and SaveManager.is_dev_mode():
			modal_status.text = "🛠️ Dev Mode Unlocked (Normal: Requires Ch. %d)" % (level_num - 1)
			modal_status.add_theme_color_override("font_color", Color("#FBBF24"))
		else:
			modal_status.text = "Unlocked • Ready for Quest"
			modal_status.add_theme_color_override("font_color", Color("#10B981"))
		modal_travel_btn.disabled = false
		if level_num == 6:
			modal_travel_btn.text = "⚡ Infiltrate the Citadel ➔"
		else:
			modal_travel_btn.text = "⚔️ Travel to %s" % info["name"]
	else:
		modal_status.text = "Locked (Requires Chapter %d Completion)" % (level_num - 1)
		modal_status.add_theme_color_override("font_color", Color("#EF4444"))
		modal_travel_btn.disabled = true
		modal_travel_btn.text = "🔒 Locked"

	if modal_intro_btn:
		if level_num == 1:
			modal_intro_btn.visible = true
			modal_intro_btn.text = "🎬 Watch Prologue"
		elif level_num == 5 and (real_unlocked >= 6 or SaveManager.is_dev_mode()):
			modal_intro_btn.visible = true
			modal_intro_btn.text = "🎬 The Plot Twist"
		elif level_num == 6 and (real_unlocked >= 6 or SaveManager.is_dev_mode()):
			modal_intro_btn.visible = true
			modal_intro_btn.text = "🎬 The Confrontation"
		else:
			modal_intro_btn.visible = false

	modal_overlay.visible = true

	var card = $ModalOverlay/Center/Card
	card.scale = Vector2(0.9, 0.9)
	var card_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	card_tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.25)

func _on_close_modal() -> void:
	modal_overlay.visible = false

func _on_confirm_travel() -> void:
	SaveManager.user_profile["current_level"] = selected_level_num
	SaveManager.save_local_profile()
	modal_overlay.visible = false

	if selected_level_num == 1:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_1)
	elif selected_level_num == 2:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_2)
	elif selected_level_num == 3:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_3)
	elif selected_level_num == 4:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_4)
	elif selected_level_num == 5:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_5)
	elif selected_level_num == 6:
		if not bool(SaveManager.user_profile.get("cutscene_segfault_seen", false)):
			SceneManager.change_scene_with_loading(SceneManager.CUTSCENE_THRONE)
		else:
			SceneManager.change_scene_with_loading(SceneManager.WORLD_6)
	else:
		SceneManager.change_scene_with_loading(SceneManager.LEVEL_GAMEPLAY)

func _on_back_button_pressed() -> void:
	SceneManager.change_scene(SceneManager.MAIN_MENU)
