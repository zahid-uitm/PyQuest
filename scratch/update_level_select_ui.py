script_content = '''# res://scripts/ui/LevelSelectUI.gd
extends Control

const LEVELS_DATA = [
	{
		"level": 1,
		"name": "Variable Valley",
		"chapter": "CHAPTER 1",
		"topic": "Variables & Data Types",
		"desc": "Explore the lush valley of Pythonia. Meet Master PyWizard, unlock ancient rune chests, and master Python variable declarations and type casting.",
		"icon": "🌿",
		"pos": Vector2(260, 670),
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
		"icon": "⚖️",
		"pos": Vector2(620, 360),
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
		"pos": Vector2(980, 670),
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
		"icon": "📜",
		"pos": Vector2(1340, 360),
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
		"topic": "Boss Battle Integration",
		"desc": "The volcanic summit of Pythonia: engage in a turn-based coding battle against the legendary Guardian, synthesizing all your Python fundamentals.",
		"icon": "🐉",
		"pos": Vector2(1680, 670),
		"color": Color("#DC2626"),       # Molten Ruby Crimson
		"color_dark": Color("#7F1D1D"),
		"color_light": Color("#FCA5A5"),
		"zone_title": "Molten Obsidian Citadel",
		"badge": "🌋 VOLCANIC SUMMIT"
	}
]

# Top Bar Nodes
@onready var back_button: Button = $HeaderPanel/Header/BackButton
@onready var progress_label: Label = $HeaderPanel/Header/ProgressLabel
@onready var stars_total_label: Label = $HeaderPanel/Header/StarsTotalLabel

# Map Canvas Nodes
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

var selected_level_num: int = 1
var alex_token: Control = null
var alex_current_pos: Vector2 = Vector2.ZERO
var is_alex_hopping: bool = false
var energy_pulse_t: float = 0.0

func _ready() -> void:
	modal_overlay.visible = false
	back_button.pressed.connect(_on_back_button_pressed)
	modal_close_btn.pressed.connect(_on_close_modal)
	modal_travel_btn.pressed.connect(_on_confirm_travel)

	biome_canvas.draw.connect(_on_draw_biomes)
	path_drawer.draw.connect(_on_draw_saga_road)
	if fog_canvas:
		fog_canvas.draw.connect(_on_draw_fog)

	build_map()

func _process(delta: float) -> void:
	energy_pulse_t = fmod(energy_pulse_t + delta * 0.35, 1.0)
	if path_drawer:
		path_drawer.queue_redraw()

func build_map() -> void:
	for child in nodes_container.get_children():
		child.queue_free()

	if alex_token_layer:
		for child in alex_token_layer.get_children():
			child.queue_free()

	var unlocked_level: int = int(SaveManager.user_profile.get("unlocked_level", 1))
	var current_level: int = int(SaveManager.user_profile.get("current_level", 1))
	if current_level > unlocked_level:
		current_level = unlocked_level
	var stars_dict: Dictionary = SaveManager.user_profile.get("level_stars", {})

	var total_stars: int = 0
	for k in stars_dict.keys():
		total_stars += int(stars_dict[k])

	progress_label.text = "World %d of %d" % [min(unlocked_level, LEVELS_DATA.size()), LEVELS_DATA.size()]
	stars_total_label.text = "⭐ %d / 15 Stars" % total_stars

	for info in LEVELS_DATA:
		var lvl: int = info["level"]
		var is_unlocked: bool = lvl <= unlocked_level
		var is_current: bool = (lvl == current_level)
		var star_count: int = int(stars_dict.get(str(lvl), 0))

		var node_btn = _create_tactile_landmark_node(info, is_unlocked, is_current, star_count)
		node_btn.position = info["pos"] - Vector2(60, 60)
		nodes_container.add_child(node_btn)

	_spawn_alex_token(current_level)

	biome_canvas.queue_redraw()
	path_drawer.queue_redraw()
	if fog_canvas:
		fog_canvas.queue_redraw()

# -------------------------------------------------------------
# ALEX LIVING CHARACTER TOKEN
# -------------------------------------------------------------
func _spawn_alex_token(level_num: int) -> void:
	if not alex_token_layer:
		return

	var info: Dictionary = LEVELS_DATA[level_num - 1]
	alex_current_pos = info["pos"]

	alex_token = Control.new()
	alex_token.size = Vector2(64, 84)
	alex_token.position = alex_current_pos - Vector2(32, 95)
	alex_token.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Sprite Container
	var sprite_rect = TextureRect.new()
	sprite_rect.size = Vector2(56, 56)
	sprite_rect.position = Vector2(4, 28)
	sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Use Alex front idle sprite from player.png
	var player_sheet = load("res://assets/sprites/characters/player.png")
	if player_sheet:
		var atlas = AtlasTexture.new()
		atlas.atlas = player_sheet
		atlas.region = Rect2(0, 0, 48, 48)
		sprite_rect.texture = atlas

	alex_token.add_child(sprite_rect)

	# "YOU ARE HERE" Wooden Indicator Arrow
	var pin_vbox = VBoxContainer.new()
	pin_vbox.position = Vector2(-28, -20)
	pin_vbox.size = Vector2(120, 44)
	pin_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pin_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pin_panel = PanelContainer.new()
	var pin_style = StyleBoxFlat.new()
	pin_style.bg_color = Color("#854D0E") # Warm carved oak
	pin_style.border_color = Color("#FDE047")
	pin_style.set_border_width_all(2)
	pin_style.set_corner_radius_all(6)
	pin_style.content_margin_left = 6
	pin_style.content_margin_right = 6
	pin_style.content_margin_top = 2
	pin_style.content_margin_bottom = 2
	pin_panel.add_theme_stylebox_override("panel", pin_style)

	var pin_tag = Label.new()
	pin_tag.text = "📍 ALEX"
	pin_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pin_tag.add_theme_font_size_override("font_size", 11)
	pin_tag.add_theme_color_override("font_color", Color("#FEF08A"))
	pin_tag.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	pin_tag.add_theme_constant_override("shadow_offset_y", 1)
	pin_panel.add_child(pin_tag)
	pin_vbox.add_child(pin_panel)

	alex_token.add_child(pin_vbox)

	# Gentle bobbing animation
	var bob_tween = alex_token.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob_tween.tween_property(sprite_rect, "position:y", 25.0, 1.2)
	bob_tween.tween_property(sprite_rect, "position:y", 31.0, 1.2)

	alex_token_layer.add_child(alex_token)

func _hop_alex_to_level(target_level_num: int) -> void:
	if not alex_token or is_alex_hopping:
		_open_level_modal(target_level_num)
		return

	var target_info: Dictionary = LEVELS_DATA[target_level_num - 1]
	var target_pos: Vector2 = target_info["pos"] - Vector2(32, 95)

	if alex_token.position.distance_to(target_pos) < 10.0:
		_open_level_modal(target_level_num)
		return

	is_alex_hopping = true
	var start_pos = alex_token.position

	# Parabolic jumping hop tween like Super Mario World
	var hop_tween = create_tween().set_parallel(true)
	hop_tween.tween_property(alex_token, "position:x", target_pos.x, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Y has an arched jump motion
	var hop_y = create_tween().set_trans(Tween.TRANS_QUAD)
	var peak_y = min(start_pos.y, target_pos.y) - 45.0
	hop_y.tween_property(alex_token, "position:y", peak_y, 0.28).set_ease(Tween.EASE_OUT)
	hop_y.tween_property(alex_token, "position:y", target_pos.y, 0.27).set_ease(Tween.EASE_IN)

	await hop_y.finished
	is_alex_hopping = false
	alex_current_pos = target_info["pos"]

	# Landing squash & stretch bounce
	var land_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	land_tween.tween_property(alex_token, "scale", Vector2(1.2, 0.8), 0.1)
	land_tween.tween_property(alex_token, "scale", Vector2(1.0, 1.0), 0.15)
	await land_tween.finished

	_open_level_modal(target_level_num)

# -------------------------------------------------------------
# DRAWING 5 THEMED BIOME REGIONS & VINTAGE PARCHMENT ACCENTS
# -------------------------------------------------------------
func _on_draw_biomes() -> void:
	var total_w = 1920.0
	var total_h = 1080.0
	var col_w = total_w / 5.0

	for i in range(LEVELS_DATA.size()):
		var info = LEVELS_DATA[i]
		var x_start = i * col_w
		
		# Gentle vertical biome glow tint over the ancient map
		var tint_col = info["color"]
		tint_col.a = 0.08
		biome_canvas.draw_rect(Rect2(x_start, 0, col_w, total_h), tint_col)

		# Biome boundary seam
		if i > 0:
			var seam_col = Color("#5C3B1E")
			seam_col.a = 0.35
			biome_canvas.draw_line(Vector2(x_start, 0), Vector2(x_start, total_h), seam_col, 2.0)

		# Carved Chapter Banner Title on the top region
		var banner_rect = Rect2(x_start + 16, 24, col_w - 32, 38)
		biome_canvas.draw_rect(banner_rect, Color(0.12, 0.08, 0.04, 0.75), true)
		var banner_border = info["color"]
		banner_border.a = 0.6
		biome_canvas.draw_rect(banner_rect, banner_border, false, 2.0)

# -------------------------------------------------------------
# DRAWING THE WINDING COBBLESTONE SAGA ROAD WITH ENERGY PULSE
# -------------------------------------------------------------
func _on_draw_saga_road() -> void:
	var unlocked_level: int = int(SaveManager.user_profile.get("unlocked_level", 1))

	var full_curve_points: Array[Vector2] = []
	for i in range(LEVELS_DATA.size() - 1):
		var p0 = LEVELS_DATA[i]["pos"]
		var p3 = LEVELS_DATA[i + 1]["pos"]
		var mid_x = (p0.x + p3.x) * 0.5
		var p1 = Vector2(mid_x, p0.y)
		var p2 = Vector2(mid_x, p3.y)

		var seg_points = _sample_cubic_bezier(p0, p1, p2, p3, 24)
		if i > 0 and seg_points.size() > 0:
			seg_points.remove_at(0)
		full_curve_points.append_array(seg_points)

	if full_curve_points.size() < 2:
		return

	# Layer 1: Road Drop Shadow on Parchment
	var shadow_pts = PackedVector2Array()
	for pt in full_curve_points:
		shadow_pts.append(pt + Vector2(0, 10))
	path_drawer.draw_polyline(shadow_pts, Color(0.12, 0.07, 0.03, 0.75), 56.0)

	# Layer 2: Road Dirt Trench / Dark Cobblestone Outer Edge
	var trench_pts = PackedVector2Array()
	for pt in full_curve_points:
		trench_pts.append(pt)
	path_drawer.draw_polyline(trench_pts, Color("#3B2213"), 46.0)

	# Layer 3: Warm Cobblestone Paver Trail
	path_drawer.draw_polyline(trench_pts, Color("#D7BC8A"), 32.0)

	# Layer 4: Segment Cobblestones & Center Dashed Guideline
	for i in range(LEVELS_DATA.size() - 1):
		var p0 = LEVELS_DATA[i]["pos"]
		var p3 = LEVELS_DATA[i + 1]["pos"]
		var mid_x = (p0.x + p3.x) * 0.5
		var p1 = Vector2(mid_x, p0.y)
		var p2 = Vector2(mid_x, p3.y)
		var seg = _sample_cubic_bezier(p0, p1, p2, p3, 24)

		var is_seg_unlocked = (i + 1) < unlocked_level
		var center_color = Color("#FFFBEB") if is_seg_unlocked else Color("#64748B")
		_draw_dashed_curve(path_drawer, seg, center_color, 4.0, 14.0, 14.0)

	# Layer 5: Glowing Energy Spark traveling along unlocked road
	if unlocked_level > 1 and full_curve_points.size() > 10:
		var max_seg_idx = min(unlocked_level - 1, LEVELS_DATA.size() - 1)
		var unlocked_pts_count = int(float(full_curve_points.size()) * (float(max_seg_idx) / float(LEVELS_DATA.size() - 1)))
		if unlocked_pts_count > 2:
			var target_idx = int(energy_pulse_t * float(unlocked_pts_count - 1))
			var pulse_pt = full_curve_points[clamp(target_idx, 0, unlocked_pts_count - 1)]
			# Draw golden glowing light mote
			path_drawer.draw_circle(pulse_pt, 12.0, Color(1.0, 0.85, 0.3, 0.35))
			path_drawer.draw_circle(pulse_pt, 7.0, Color(1.0, 0.95, 0.6, 0.85))
			path_drawer.draw_circle(pulse_pt, 3.5, Color(1.0, 1.0, 1.0, 1.0))

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
# FOG OF WAR DRAWING FOR LOCKED REGIONS
# -------------------------------------------------------------
func _on_draw_fog() -> void:
	if not fog_canvas:
		return

	var unlocked_level: int = int(SaveManager.user_profile.get("unlocked_level", 1))
	var total_w = 1920.0
	var total_h = 1080.0
	var col_w = total_w / 5.0

	for i in range(LEVELS_DATA.size()):
		var info = LEVELS_DATA[i]
		var lvl = info["level"]
		if lvl > unlocked_level:
			var x_start = i * col_w
			var fog_rect = Rect2(x_start, 0, col_w, total_h)
			
			# Mystical dark cloud fog blanket
			fog_canvas.draw_rect(fog_rect, Color(0.05, 0.04, 0.08, 0.72))
			
			# Soft cloud puffs
			var center_y = info["pos"].y
			fog_canvas.draw_circle(Vector2(x_start + col_w * 0.5, center_y), 150.0, Color(0.04, 0.03, 0.07, 0.45))
			fog_canvas.draw_circle(Vector2(x_start + col_w * 0.3, center_y - 60.0), 120.0, Color(0.04, 0.03, 0.07, 0.4))
			fog_canvas.draw_circle(Vector2(x_start + col_w * 0.7, center_y + 60.0), 120.0, Color(0.04, 0.03, 0.07, 0.4))

			# Heavy Iron Chains across locked zone
			var chain_start = Vector2(x_start, center_y - 30)
			var chain_end = Vector2(x_start + col_w, center_y + 30)
			fog_canvas.draw_line(chain_start, chain_end, Color(0.18, 0.15, 0.20, 0.85), 6.0)

# -------------------------------------------------------------
# TACTILE WORLD LANDMARKS (PVZ PHYSICAL 3D DIORAMA PEDESTAL)
# -------------------------------------------------------------
func _create_tactile_landmark_node(info: Dictionary, is_unlocked: bool, is_current: bool, star_count: int) -> Control:
	var root = Control.new()
	root.custom_minimum_size = Vector2(120, 120)
	root.size = Vector2(120, 120)
	root.pivot_offset = Vector2(60, 60)

	# --- 1. Arch of 3 Large Golden Stars ---
	var stars_control = Control.new()
	stars_control.size = Vector2(120, 44)
	stars_control.position = Vector2(0, -42)
	stars_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stars_control)

	var star_offsets = [
		{"pos": Vector2(16, 12), "rot": -0.30, "scale": 1.0, "idx": 0},
		{"pos": Vector2(46, 0),  "rot": 0.0,   "scale": 1.35, "idx": 1},
		{"pos": Vector2(78, 12), "rot": 0.30,  "scale": 1.0, "idx": 2}
	]

	for st in star_offsets:
		var s_lbl = Label.new()
		var earned = is_unlocked and (st["idx"] < star_count)
		s_lbl.text = "★"
		s_lbl.position = st["pos"]
		s_lbl.rotation = st["rot"]
		s_lbl.scale = Vector2(st["scale"], st["scale"])
		s_lbl.add_theme_font_size_override("font_size", 24)
		if earned:
			s_lbl.add_theme_color_override("font_color", Color("#FBBF24")) # Gleaming gold
			s_lbl.add_theme_color_override("font_shadow_color", Color("#B45309"))
			s_lbl.add_theme_constant_override("shadow_offset_y", 2)
		else:
			s_lbl.add_theme_color_override("font_color", Color("#475569") if is_unlocked else Color("#1E293B"))
			s_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		stars_control.add_child(s_lbl)

	# --- 2. 3D Tactile Pedestal Button ---
	var btn = Button.new()
	btn.position = Vector2(0, 0)
	btn.size = Vector2(120, 120)
	btn.custom_minimum_size = Vector2(120, 120)
	btn.focus_mode = Control.FOCUS_NONE

	var theme_col: Color = info["color"]
	var theme_dark: Color = info["color_dark"]
	var theme_light: Color = info["color_light"]

	var style_normal = StyleBoxFlat.new()
	style_normal.corner_radius_top_left = 60
	style_normal.corner_radius_top_right = 60
	style_normal.corner_radius_bottom_right = 60
	style_normal.corner_radius_bottom_left = 60
	style_normal.set_border_width_all(5)

	if is_unlocked:
		style_normal.bg_color = theme_col
		style_normal.border_color = theme_light
		style_normal.shadow_color = theme_dark
		style_normal.shadow_size = 12
		style_normal.shadow_offset = Vector2(0, 8)
		btn.text = "%s\n%d" % [info["icon"], info["level"]]
		btn.add_theme_font_size_override("font_size", 26)
		btn.add_theme_color_override("font_color", Color("#FFFFFF"))
		btn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		btn.add_theme_constant_override("shadow_offset_y", 2)
	else:
		style_normal.bg_color = Color("#1E293B")
		style_normal.border_color = Color("#475569")
		style_normal.shadow_color = Color("#0F172A")
		style_normal.shadow_size = 8
		style_normal.shadow_offset = Vector2(0, 6)
		btn.text = "🔒\n%d" % info["level"]
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_color_override("font_color", Color("#64748B"))

	btn.add_theme_stylebox_override("normal", style_normal)

	# Hover style
	var style_hover = style_normal.duplicate() as StyleBoxFlat
	if is_unlocked:
		style_hover.bg_color = theme_light
		style_hover.shadow_size = 16
		style_hover.shadow_offset = Vector2(0, 12)
	btn.add_theme_stylebox_override("hover", style_hover)

	# PvZ-style squash & stretch spring hover animations
	btn.mouse_entered.connect(func():
		var tween = root.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(root, "scale", Vector2(1.10, 1.10), 0.2)
	)
	btn.mouse_exited.connect(func():
		var tween = root.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(root, "scale", Vector2(1.0, 1.0), 0.25)
	)

	btn.pressed.connect(func():
		if is_unlocked:
			_hop_alex_to_level(info["level"])
		else:
			_open_level_modal(info["level"])
	)
	root.add_child(btn)

	# --- 3. Carved Wooden Chapter Ribbon Below ---
	var ribbon = PanelContainer.new()
	ribbon.position = Vector2(-25, 126)
	ribbon.size = Vector2(170, 28)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ribbon_style = StyleBoxFlat.new()
	ribbon_style.bg_color = Color(0.22, 0.14, 0.08, 0.95)
	ribbon_style.border_color = theme_col if is_unlocked else Color("#475569")
	ribbon_style.set_border_width_all(2)
	ribbon_style.set_corner_radius_all(6)
	ribbon_style.shadow_color = Color(0, 0, 0, 0.6)
	ribbon_style.shadow_size = 4
	ribbon_style.shadow_offset = Vector2(0, 2)
	ribbon.add_theme_stylebox_override("panel", ribbon_style)

	var ribbon_label = Label.new()
	ribbon_label.text = info["name"]
	ribbon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon_label.add_theme_font_size_override("font_size", 12)
	ribbon_label.add_theme_color_override("font_color", Color("#FEF3C7") if is_unlocked else Color("#94A3B8"))
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
	var unlocked_level: int = int(SaveManager.user_profile.get("unlocked_level", 1))
	var stars_dict: Dictionary = SaveManager.user_profile.get("level_stars", {})
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
		modal_status.text = "Unlocked • Ready for Quest"
		modal_status.add_theme_color_override("font_color", Color("#10B981"))
		modal_travel_btn.disabled = false
		modal_travel_btn.text = "⚔️ Travel to %s" % info["name"]
	else:
		modal_status.text = "Locked (Requires Chapter %d Completion)" % (level_num - 1)
		modal_status.add_theme_color_override("font_color", Color("#EF4444"))
		modal_travel_btn.disabled = true
		modal_travel_btn.text = "🔒 Locked"

	modal_overlay.visible = true

	# Smooth pop-in animation
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
		SceneManager.change_scene(SceneManager.WORLD_1)
	else:
		SceneManager.change_scene(SceneManager.LEVEL_GAMEPLAY)

func _on_back_button_pressed() -> void:
	SceneManager.change_scene(SceneManager.MAIN_MENU)
'''

with open("c:/Users/zahid/Documents/py-quest/scripts/ui/LevelSelectUI.gd", "w", encoding="utf-8") as f:
    f.write(script_content)

print("SUCCESS: Updated scripts/ui/LevelSelectUI.gd")

