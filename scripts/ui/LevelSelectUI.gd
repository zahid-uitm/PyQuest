# res://scripts/ui/LevelSelectUI.gd
extends Control

const LEVELS_DATA = [
	{
		"level": 1,
		"name": "Variable Valley",
		"topic": "Variables & Data Types",
		"desc": "Unlock Ancient Chests",
		"icon": "📦"
	},
	{
		"level": 2,
		"name": "Chamber of Conditions",
		"topic": "Control Structures (if/loops)",
		"desc": "Traps & Bridges",
		"icon": "⚡"
	},
	{
		"level": 3,
		"name": "Relic Vault",
		"topic": "Functions & Modularity",
		"desc": "Spell Invocations",
		"icon": "🔮"
	},
	{
		"level": 4,
		"name": "The Catacombs",
		"topic": "Lists & Sequences",
		"desc": "Inventory Arrays",
		"icon": "📜"
	},
	{
		"level": 5,
		"name": "The Guardian's Lair",
		"topic": "Boss Integration",
		"desc": "Final Boss Battle",
		"icon": "👑"
	}
]

@onready var grid_container: GridContainer = $MainContainer/ScrollContainer/GridContainer
@onready var back_button: Button = $HeaderPanel/Header/BackButton
@onready var progress_label: Label = $HeaderPanel/Header/ProgressLabel

func _ready() -> void:
	if back_button and not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)
	
	setup_level_grid()

func setup_level_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	var unlocked_level: int = int(SaveManager.user_profile.get("unlocked_level", 1))
	var stars_dict: Dictionary = SaveManager.user_profile.get("level_stars", {})

	if progress_label:
		progress_label.text = "Unlocked: %d / %d Chapters" % [min(unlocked_level, LEVELS_DATA.size()), LEVELS_DATA.size()]

	for info in LEVELS_DATA:
		var level_num: int = info["level"]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(280, 240)
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		var is_unlocked: bool = level_num <= unlocked_level
		btn.disabled = not is_unlocked
		
		var star_count: int = int(stars_dict.get(str(level_num), 0))
		var stars_str = ""
		for s in range(3):
			stars_str += "★" if s < star_count else "☆"

		if is_unlocked:
			btn.text = "%s CHAPTER %d\n\n%s\n\n[%s]\n\n%s\n\n▶ ENTER QUEST" % [
				info["icon"],
				level_num,
				info["name"],
				info["topic"],
				stars_str
			]
			_apply_unlocked_style(btn)
			btn.pressed.connect(_on_level_selected.bind(level_num))
		else:
			btn.text = "🔒 CHAPTER %d\n\n%s\n\n[%s]\n\nLOCKED" % [
				level_num,
				info["name"],
				info["topic"]
			]
			_apply_locked_style(btn)

		grid_container.add_child(btn)

func _apply_unlocked_style(btn: Button) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color("#161F33")
	style_normal.border_color = Color("#F59E0B")
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(12)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color("#1E293B")
	style_hover.border_color = Color("#FBBF24")
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(12)
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color("#0D1527")
	style_pressed.border_color = Color("#D4AF37")
	style_pressed.set_border_width_all(2)
	style_pressed.set_corner_radius_all(12)

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_color_override("font_color", Color("#FFFFFF"))
	btn.add_theme_color_override("font_hover_color", Color("#F59E0B"))
	btn.add_theme_font_size_override("font_size", 15)

func _apply_locked_style(btn: Button) -> void:
	var style_disabled = StyleBoxFlat.new()
	style_disabled.bg_color = Color("#0D1527")
	style_disabled.border_color = Color("#1E293B")
	style_disabled.set_border_width_all(1)
	style_disabled.set_corner_radius_all(12)

	btn.add_theme_stylebox_override("disabled", style_disabled)
	btn.add_theme_color_override("font_disabled_color", Color("#475569"))
	btn.add_theme_font_size_override("font_size", 14)

func _on_level_selected(level_num: int) -> void:
	print("Selected Level: %d" % level_num)
	SaveManager.user_profile["current_level"] = level_num
	SceneManager.change_scene(SceneManager.WORLD_1)

func _on_back_button_pressed() -> void:
	SceneManager.change_scene(SceneManager.MAIN_MENU)
