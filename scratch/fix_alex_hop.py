path = "c:/Users/zahid/Documents/py-quest/scripts/ui/LevelSelectUI.gd"
with open(path, "r", encoding="utf-8") as f:
    code = f.read()

# 1. Update state variables declaration
old_vars = """var selected_level_num: int = 1
var alex_token: Control = null
var alex_current_pos: Vector2 = Vector2.ZERO
var is_alex_hopping: bool = false
var energy_pulse_t: float = 0.0"""

new_vars = """var selected_level_num: int = 1
var alex_token: Control = null
var token_visuals: Control = null
var alex_bob_tween: Tween = null
var alex_current_pos: Vector2 = Vector2.ZERO
var is_alex_hopping: bool = false
var energy_pulse_t: float = 0.0"""

assert old_vars in code, "old_vars not found!"
code = code.replace(old_vars, new_vars, 1)

# 2. Update _spawn_alex_token and _hop_alex_to_level
old_funcs = """# -------------------------------------------------------------
# ALEX LIVING CHARACTER TOKEN
# -------------------------------------------------------------
func _spawn_alex_token(level_num: int) -> void:
	if not alex_token_layer:
		return

	var info: Dictionary = LEVELS_DATA[level_num - 1]
	alex_current_pos = info["pos"]

	alex_token = Control.new()
	alex_token.size = Vector2(48, 64)
	alex_token.position = alex_current_pos - Vector2(24, 78)
	alex_token.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Sprite Container
	var sprite_rect = TextureRect.new()
	sprite_rect.size = Vector2(48, 48)
	sprite_rect.position = Vector2(0, 16)
	sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var player_sheet = load("res://assets/sprites/characters/player.png")
	if player_sheet:
		var atlas = AtlasTexture.new()
		atlas.atlas = player_sheet
		atlas.region = Rect2(0, 0, 48, 48)
		sprite_rect.texture = atlas

	alex_token.add_child(sprite_rect)

	# "ALEX" Pointer Placard
	var pin_panel = PanelContainer.new()
	pin_panel.position = Vector2(-16, -10)
	pin_panel.size = Vector2(80, 22)
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
	alex_token.add_child(pin_panel)

	# Gentle bobbing animation
	var bob_tween = alex_token.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob_tween.tween_property(alex_token, "position:y", alex_current_pos.y - 82.0, 1.2)
	bob_tween.tween_property(alex_token, "position:y", alex_current_pos.y - 74.0, 1.2)

	alex_token_layer.add_child(alex_token)

func _hop_alex_to_level(target_level_num: int) -> void:
	if not alex_token or is_alex_hopping:
		_open_level_modal(target_level_num)
		return

	var target_info: Dictionary = LEVELS_DATA[target_level_num - 1]
	var target_pos: Vector2 = target_info["pos"] - Vector2(24, 78)

	if alex_token.position.distance_to(target_pos) < 15.0:
		_open_level_modal(target_level_num)
		return

	is_alex_hopping = true
	var start_pos = alex_token.position

	var hop_tween = create_tween().set_parallel(true)
	hop_tween.tween_property(alex_token, "position:x", target_pos.x, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var hop_y = create_tween().set_trans(Tween.TRANS_QUAD)
	var peak_y = min(start_pos.y, target_pos.y) - 50.0
	hop_y.tween_property(alex_token, "position:y", peak_y, 0.28).set_ease(Tween.EASE_OUT)
	hop_y.tween_property(alex_token, "position:y", target_pos.y, 0.27).set_ease(Tween.EASE_IN)

	await hop_y.finished
	is_alex_hopping = false
	alex_current_pos = target_info["pos"]

	var land_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	land_tween.tween_property(alex_token, "scale", Vector2(1.2, 0.8), 0.1)
	land_tween.tween_property(alex_token, "scale", Vector2(1.0, 1.0), 0.15)
	await land_tween.finished

	_open_level_modal(target_level_num)"""

new_funcs = """# -------------------------------------------------------------
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

	_open_level_modal(target_level_num)"""

assert old_funcs in code, "old_funcs not found!"
code = code.replace(old_funcs, new_funcs, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(code)

print("SUCCESS: Updated LevelSelectUI.gd with accurate hop animation!")

