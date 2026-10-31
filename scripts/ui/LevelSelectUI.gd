# res://scripts/ui/LevelSelectUI.gd
extends Control

const LEVELS_DATA = [
	{
		"level": 1,
		"name": "Variable Valley",
		"chapter": "CHAPTER 1",
		"topic": "Variables & Data Types",
		"desc": "Explore the lush valley of Pythonia. Meet Master PyWizard, unlock ancient rune chests, and master Python variable declarations and type casting.",
		"icon": "🌿",
		"pos": Vector2(210, 680),
		"color": Color("#10B981"),       # Emerald Green
		"color_dark": Color("#064E3B"),
		"color_light": Color("#6EE7B7"),
		"zone_bg_from": Color(0.04, 0.18, 0.10, 0.95),
		"zone_bg_to": Color(0.02, 0.07, 0.04, 0.95),
		"props": ["🌲", "🪨", "🌳", "🌱"]
	},
	{
		"level": 2,
		"name": "Chamber of Conditions",
		"chapter": "CHAPTER 2",
		"topic": "Control Structures (if / loops)",
		"desc": "Cross treacherous chasms with collapsing bridges and dangerous traps. Write conditional checks and loops to guide Alex across safely.",
		"icon": "⚖️",
		"pos": Vector2(585, 340),
		"color": Color("#0284C7"),       # Lapis Blue / Sky
		"color_dark": Color("#0C4A6E"),
		"color_light": Color("#7DD3FC"),
		"zone_bg_from": Color(0.04, 0.14, 0.24, 0.95),
		"zone_bg_to": Color(0.02, 0.06, 0.11, 0.95),
		"props": ["💎", "🌉", "🧊", "⚡"]
	},
	{
		"level": 3,
		"name": "Relic Vault",
		"chapter": "CHAPTER 3",
		"topic": "Functions & Modularity",
		"desc": "An ancient subterranean sanctuary of arcane knowledge. Harness reusable functions and parameters to break magical seals.",
		"icon": "🔮",
		"pos": Vector2(960, 680),
		"color": Color("#9333EA"),       # Arcane Purple
		"color_dark": Color("#581C87"),
		"color_light": Color("#D8B4FE"),
		"zone_bg_from": Color(0.15, 0.06, 0.22, 0.95),
		"zone_bg_to": Color(0.06, 0.02, 0.10, 0.95),
		"props": ["🔮", "✨", "🏛️", "🕯️"]
	},
	{
		"level": 4,
		"name": "The Catacombs",
		"chapter": "CHAPTER 4",
		"topic": "Lists & Sequences",
		"desc": "Navigate the winding underground crypts. Organize inventory matrices, search lists for hidden keys, and manipulate array elements.",
		"icon": "📜",
		"pos": Vector2(1335, 340),
		"color": Color("#D97706"),       # Ancient Amber Gold
		"color_dark": Color("#78350F"),
		"color_light": Color("#FDE68A"),
		"zone_bg_from": Color(0.18, 0.10, 0.04, 0.95),
		"zone_bg_to": Color(0.08, 0.04, 0.01, 0.95),
		"props": ["🏺", "🗝️", "📜", "🪙"]
	},
	{
		"level": 5,
		"name": "The Guardian's Lair",
		"chapter": "CHAPTER 5",
		"topic": "Boss Battle Integration",
		"desc": "The volcanic summit of Pythonia: engage in a turn-based coding battle against the legendary Guardian, synthesizing all your Python fundamentals.",
		"icon": "🐉",
		"pos": Vector2(1710, 680),
		"color": Color("#DC2626"),       # Molten Ruby Crimson
		"color_dark": Color("#7F1D1D"),
		"color_light": Color("#FCA5A5"),
		"zone_bg_from": Color(0.20, 0.04, 0.04, 0.95),
		"zone_bg_to": Color(0.09, 0.01, 0.01, 0.95),
		"props": ["🌋", "🔥", "👑", "⚔️"]
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

func _ready() -> void:
	modal_overlay.visible = false
	back_button.pressed.connect(_on_back_button_pressed)
	modal_close_btn.pressed.connect(_on_close_modal)
	modal_travel_btn.pressed.connect(_on_confirm_travel)

	biome_canvas.draw.connect(_on_draw_biomes)
	path_drawer.draw.connect(_on_draw_saga_road)
	build_map()

func build_map() -> void:
	for child in nodes_container.get_children():
		child.queue_free()

	var unlocked_level: int = int(SaveManager.user_profile.get("unlocked_level", 1))
	var current_level: int = int(SaveManager.user_profile.get("current_level", 1))
	var stars_dict: Dictionary = SaveManager.user_profile.get("level_stars", {})

	var total_stars: int = 0
	for k in stars_dict.keys():
		total_stars += int(stars_dict[k])

	progress_label.text = "World %d of %d" % [min(unlocked_level, LEVELS_DATA.size()), LEVELS_DATA.size()]
	stars_total_label.text = "⭐ %d / 15 Stars" % total_stars

	for info in LEVELS_DATA:
		var lvl: int = info["level"]
		var is_unlocked: bool = lvl <= unlocked_level
		var is_current: bool = (lvl == current_level) or (lvl == unlocked_level and current_level > unlocked_level)
		var star_count: int = int(stars_dict.get(str(lvl), 0))

		var node_btn = _create_stepping_stone_node(info, is_unlocked, is_current, star_count)
		node_btn.position = info["pos"] - Vector2(50, 50)
		nodes_container.add_child(node_btn)

	biome_canvas.queue_redraw()
	path_drawer.queue_redraw()

# -------------------------------------------------------------
# DRAWING 5 THEMED BIOME REGIONS
# -------------------------------------------------------------
func _on_draw_biomes() -> void:
	var total_w = 1920.0
	var total_h = 1080.0
	var col_w = total_w / 5.0

	for i in range(LEVELS_DATA.size()):
		var info = LEVELS_DATA[i]
		var x_start = i * col_w
		var rect = Rect2(x_start, 0, col_w, total_h)

		# Vertical gradient stripe for the biome
		var bg_color = info["zone_bg_from"]
		biome_canvas.draw_rect(rect, bg_color)
		
		# Dark bottom gradient shading
		var bottom_shade = Rect2(x_start, total_h * 0.5, col_w, total_h * 0.5)
		biome_canvas.draw_rect(bottom_shade, Color(0, 0, 0, 0.35))

		# Biome separator border
		if i > 0:
			var border_col = info["color"]
			border_col.a = 0.25
			biome_canvas.draw_line(Vector2(x_start, 0), Vector2(x_start, total_h), border_col, 2.0)

		# Biome header banner in each zone
		var zone_rect = Rect2(x_start + 14, 110, col_w - 28, 42)
		biome_canvas.draw_rect(zone_rect, Color(0.05, 0.08, 0.14, 0.7), true)
		var banner_border = info["color"]
		banner_border.a = 0.5
		biome_canvas.draw_rect(zone_rect, banner_border, false, 2.0)

# -------------------------------------------------------------
# DRAWING THE WINDING SAGA ROAD
# -------------------------------------------------------------
func _on_draw_saga_road() -> void:
	var unlocked_level: int = int(SaveManager.user_profile.get("unlocked_level", 1))

	# Compute smooth Bézier curve points across the 5 nodes
	var full_curve_points: Array[Vector2] = []
	for i in range(LEVELS_DATA.size() - 1):
		var p0 = LEVELS_DATA[i]["pos"]
		var p3 = LEVELS_DATA[i + 1]["pos"]
		
		# Curving control points
		var mid_x = (p0.x + p3.x) * 0.5
		var p1 = Vector2(mid_x, p0.y)
		var p2 = Vector2(mid_x, p3.y)

		var seg_points = _sample_cubic_bezier(p0, p1, p2, p3, 24)
		if i > 0 and seg_points.size() > 0:
			seg_points.remove_at(0)
		full_curve_points.append_array(seg_points)

	if full_curve_points.size() < 2:
		return

	# Layer 1: Road Drop Shadow
	var shadow_pts: PackedVector2Array = PackedVector2Array()
	for pt in full_curve_points:
		shadow_pts.append(pt + Vector2(0, 10))
	path_drawer.draw_polyline(shadow_pts, Color(0, 0, 0, 0.6), 56.0)

	# Layer 2: Road Dirt/Rock Outer Trench
	var trench_pts: PackedVector2Array = PackedVector2Array()
	for pt in full_curve_points:
		trench_pts.append(pt)
	path_drawer.draw_polyline(trench_pts, Color("#2C1810"), 48.0)

	# Layer 3: Road Sand/Cobblestone Walkway
	path_drawer.draw_polyline(trench_pts, Color("#FDE047"), 34.0)

	# Layer 4: Dashed White / Amber Guideline Center
	for i in range(LEVELS_DATA.size() - 1):
		var p0 = LEVELS_DATA[i]["pos"]
		var p3 = LEVELS_DATA[i + 1]["pos"]
		var mid_x = (p0.x + p3.x) * 0.5
		var p1 = Vector2(mid_x, p0.y)
		var p2 = Vector2(mid_x, p3.y)
		var seg = _sample_cubic_bezier(p0, p1, p2, p3, 24)

		var is_seg_unlocked = (i + 1) < unlocked_level
		var center_color = Color("#FFFFFF") if is_seg_unlocked else Color("#475569")
		_draw_dashed_curve(path_drawer, seg, center_color, 4.0, 12.0, 12.0)

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
# STEPPING-STONE CIRCULAR 3D BUTTON (MATCHING REFERENCE IMAGE)
# -------------------------------------------------------------
func _create_stepping_stone_node(info: Dictionary, is_unlocked: bool, is_current: bool, star_count: int) -> Control:
	var root = Control.new()
	root.custom_minimum_size = Vector2(100, 100)
	root.size = Vector2(100, 100)

	# --- 1. Arch of 3 Stars on top of the node ---
	var stars_control = Control.new()
	stars_control.size = Vector2(100, 40)
	stars_control.position = Vector2(0, -38)
	stars_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stars_control)

	var star_offsets = [
		{"pos": Vector2(12, 12), "rot": -0.32, "scale": 1.0, "idx": 0},
		{"pos": Vector2(38, 0),  "rot": 0.0,   "scale": 1.35, "idx": 1},
		{"pos": Vector2(66, 12), "rot": 0.32,  "scale": 1.0, "idx": 2}
	]

	for st in star_offsets:
		var s_lbl = Label.new()
		var earned = is_unlocked and (st["idx"] < star_count)
		s_lbl.text = "★"
		s_lbl.position = st["pos"]
		s_lbl.rotation = st["rot"]
		s_lbl.scale = Vector2(st["scale"], st["scale"])
		s_lbl.add_theme_font_size_override("font_size", 22)
		if earned:
			s_lbl.add_theme_color_override("font_color", Color("#FBBF24")) # Glowing golden
			s_lbl.add_theme_color_override("font_shadow_color", Color("#B45309"))
			s_lbl.add_theme_constant_override("shadow_offset_y", 2)
		else:
			s_lbl.add_theme_color_override("font_color", Color("#475569") if is_unlocked else Color("#334155"))
		stars_control.add_child(s_lbl)

	# --- 2. Active Player Pin ("YOU ARE HERE") ---
	if is_current:
		var pin_vbox = VBoxContainer.new()
		pin_vbox.position = Vector2(-25, -84)
		pin_vbox.size = Vector2(150, 40)
		pin_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		pin_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var pin_tag = Label.new()
		pin_tag.text = "📍 YOU ARE HERE"
		pin_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pin_tag.add_theme_font_size_override("font_size", 10)
		pin_tag.add_theme_color_override("font_color", Color("#F59E0B"))
		pin_vbox.add_child(pin_tag)

		var wizard_icon = Label.new()
		wizard_icon.text = "🧙"
		wizard_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wizard_icon.add_theme_font_size_override("font_size", 20)
		pin_vbox.add_child(wizard_icon)

		root.add_child(pin_vbox)

	# --- 3. 3D Circular Pedestal Button ---
	var btn = Button.new()
	btn.position = Vector2(0, 0)
	btn.size = Vector2(100, 100)
	btn.custom_minimum_size = Vector2(100, 100)
	btn.focus_mode = Control.FOCUS_NONE

	var theme_col: Color = info["color"]
	var theme_dark: Color = info["color_dark"]
	var theme_light: Color = info["color_light"]

	# Style for normal state
	var style_normal = StyleBoxFlat.new()
	style_normal.corner_radius_top_left = 50
	style_normal.corner_radius_top_right = 50
	style_normal.corner_radius_bottom_right = 50
	style_normal.corner_radius_bottom_left = 50
	style_normal.set_border_width_all(4)

	if is_unlocked:
		style_normal.bg_color = theme_col
		style_normal.border_color = theme_light
		style_normal.shadow_color = theme_dark
		style_normal.shadow_size = 10
		style_normal.shadow_offset = Vector2(0, 8) # 3D extrusion bottom
		btn.text = str(info["level"])
		btn.add_theme_font_size_override("font_size", 38)
		btn.add_theme_color_override("font_color", Color("#FFFFFF"))
		btn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		btn.add_theme_constant_override("shadow_offset_y", 3)
	else:
		style_normal.bg_color = Color("#334155")
		style_normal.border_color = Color("#64748B")
		style_normal.shadow_color = Color("#0F172A")
		style_normal.shadow_size = 8
		style_normal.shadow_offset = Vector2(0, 6)
		btn.text = "🔒"
		btn.add_theme_font_size_override("font_size", 30)

	btn.add_theme_stylebox_override("normal", style_normal)

	# Hover style
	var style_hover = style_normal.duplicate() as StyleBoxFlat
	if is_unlocked:
		style_hover.bg_color = theme_light
		style_hover.shadow_size = 14
		style_hover.shadow_offset = Vector2(0, 12)
	btn.add_theme_stylebox_override("hover", style_hover)

	btn.pressed.connect(func(): _open_level_modal(info["level"]))
	root.add_child(btn)

	# --- 4. Chapter / World Ribbon Tag underneath ---
	var ribbon = Label.new()
	ribbon.text = info["name"]
	ribbon.position = Vector2(-30, 108)
	ribbon.size = Vector2(160, 24)
	ribbon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon.add_theme_font_size_override("font_size", 12)
	ribbon.add_theme_color_override("font_color", Color("#FFFFFF") if is_unlocked else Color("#94A3B8"))
	ribbon.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	ribbon.add_theme_constant_override("shadow_offset_y", 1)
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

func _on_close_modal() -> void:
	modal_overlay.visible = false

func _on_confirm_travel() -> void:
	SaveManager.user_profile["current_level"] = selected_level_num
	SaveManager.save_local_profile()
	modal_overlay.visible = false

	# For Level 1, enter World 1
	if selected_level_num == 1:
		SceneManager.change_scene(SceneManager.WORLD_1)
	else:
		SceneManager.change_scene(SceneManager.LEVEL_GAMEPLAY)

func _on_back_button_pressed() -> void:
	SceneManager.change_scene(SceneManager.MAIN_MENU)
