# res://scripts/ui/LevelSelectUI.gd
extends Control

@export var total_levels: int = 15

@onready var grid_container: GridContainer = $MainContainer/ScrollContainer/GridContainer
@onready var back_button: Button = $HeaderPanel/Header/BackButton
@onready var progress_label: Label = $HeaderPanel/Header/ProgressLabel

func _ready() -> void:
	if back_button and not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)
	
	setup_level_grid()

func setup_level_grid() -> void:
	# Clear temporary editor placeholder buttons
	for child in grid_container.get_children():
		child.queue_free()

	var unlocked_level: int = int(SaveManager.user_profile.get("unlocked_level", 1))

	if progress_label:
		progress_label.text = "Progress: %d / %d" % [unlocked_level, total_levels]

	for level_num in range(1, total_levels + 1):
		var btn = Button.new()
		# Taller card dimensions to balance vertical screen space
		btn.custom_minimum_size = Vector2(200, 180)
		btn.focus_mode = Control.FOCUS_NONE
		
		# Expand buttons both horizontally and vertically across grid cells
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		var is_unlocked: bool = level_num <= unlocked_level
		btn.disabled = not is_unlocked
		
		if is_unlocked:
			btn.text = "LEVEL %d\n\n▶ START" % level_num
			_apply_unlocked_style(btn)
			btn.pressed.connect(_on_level_selected.bind(level_num))
		else:
			btn.text = "LEVEL %d\n\n🔒 LOCKED" % level_num
			_apply_locked_style(btn)

		grid_container.add_child(btn)

func _apply_unlocked_style(btn: Button) -> void:
	# Active Level Card - Deep Navy with Gold Accent Border
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color("#161F33")
	style_normal.border_color = Color("#F59E0B") # Gold / Amber
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(12)
	
	# Hover Glow
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color("#1E293B")
	style_hover.border_color = Color("#FBBF24")
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(12)
	
	# Pressed State
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
	btn.add_theme_font_size_override("font_size", 18)

func _apply_locked_style(btn: Button) -> void:
	# Muted Card for Locked Levels
	var style_disabled = StyleBoxFlat.new()
	style_disabled.bg_color = Color("#0D1527")
	style_disabled.border_color = Color("#1E293B")
	style_disabled.set_border_width_all(1)
	style_disabled.set_corner_radius_all(12)

	btn.add_theme_stylebox_override("disabled", style_disabled)
	btn.add_theme_color_override("font_disabled_color", Color("#475569"))
	btn.add_theme_font_size_override("font_size", 15)

func _on_level_selected(level_num: int) -> void:
	print("Selected Level: %d" % level_num)
	SaveManager.user_profile["current_level"] = level_num
	
	# Scene transition call
	if "GAMEPLAY" in SceneManager:
		SceneManager.change_scene(SceneManager.GAMEPLAY)
	else:
		print("Warning: GAMEPLAY constant not defined in SceneManager!")

func _on_back_button_pressed() -> void:
	SceneManager.change_scene(SceneManager.MAIN_MENU)
