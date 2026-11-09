# res://scripts/core/SaveManager.gd
extends Node

const GUEST_SAVE_PATH: String = "user://guest_save.json"
const USER_SAVE_PREFIX: String = "user://user_"

signal dev_mode_changed(enabled: bool)

# Runtime-only Developer Testing Mode flag (never overwrites user_profile unlocked_level on disk/cloud)
var dev_mode_enabled: bool = false
var _dev_layer: CanvasLayer = null
var _dev_bar_expanded: bool = true

# Runtime navigation state for post-boss transitions
var skip_world_intro: bool = false
var pending_map_advance_to: int = 0

# Returns the appropriate save file path based on whether the current session is a guest or logged in user
func get_current_save_path() -> String:
	if is_guest():
		return GUEST_SAVE_PATH
	var uid = FirebaseManager.current_user_id
	if uid.is_empty():
		return GUEST_SAVE_PATH
	# Sanitize UID for safe file name
	var safe_uid = uid.replace("/", "_").replace("\\", "_")
	return USER_SAVE_PREFIX + safe_uid + "_save.json"

# Active player profile dictionary used globally across the game
var user_profile: Dictionary = {
	"full_name": "Adventurer Alex",
	"is_guest": true,
	"player_level": 1,
	"xp": 0,
	"unlocked_level": 1,
	"hint_tokens": 5,
	"current_level": 1,
	"level_stars": {
		"1": 0,
		"2": 0,
		"3": 0,
		"4": 0,
		"5": 0
	},
	"settings": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"code_font_size": "medium",
		"screen_shake": true,
		"screen_flash": true,
		"show_joystick": true
	}
}

# Safely converts any value (int, float, string, or null) to int without crashing
static func safe_int(val, fallback: int = 0) -> int:
	if val == null:
		return fallback
	if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
		return int(val)
	if typeof(val) == TYPE_STRING and val.is_valid_int():
		return val.to_int()
	return fallback

func _ready() -> void:
	load_local_profile()
	# Auto-enable Developer Mode when running inside the Godot Editor; exported builds default to normal flow
	dev_mode_enabled = OS.has_feature("editor")
	_build_dev_overlay()
	_update_dev_overlay_visibility()

func is_dev_mode() -> bool:
	return dev_mode_enabled

## Returns true only the first time Alex arrives in a given world (and false when returning from a Boss Fight).
func should_play_world_intro(world_num: int) -> bool:
	if skip_world_intro:
		skip_world_intro = false
		return false
	var visited = user_profile.get("worlds_visited", [])
	if typeof(visited) != TYPE_ARRAY:
		visited = []
	for item in visited:
		if int(item) == world_num:
			return false
	visited.append(world_num)
	user_profile["worlds_visited"] = visited
	save_local_profile()
	return true

func set_dev_mode(enabled: bool) -> void:
	if dev_mode_enabled == enabled:
		return
	dev_mode_enabled = enabled
	_update_dev_overlay_visibility()
	dev_mode_changed.emit(dev_mode_enabled)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F12:
			set_dev_mode(not dev_mode_enabled)
			get_viewport().set_input_as_handled()

func _build_dev_overlay() -> void:
	_dev_layer = CanvasLayer.new()
	_dev_layer.layer = 125
	_dev_layer.name = "DevModeOverlay"
	add_child(_dev_layer)

	var panel = PanelContainer.new()
	panel.name = "DevBarPanel"
	panel.anchor_left = 0.0
	panel.anchor_top = 1.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 14.0
	panel.offset_top = -50.0
	panel.offset_right = 680.0
	panel.offset_bottom = -10.0

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.14, 0.92)
	style.border_color = Color(0.96, 0.62, 0.04, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	_dev_layer.add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	var badge_btn = _make_dev_btn("🛠️ DEV [F12]", Color("#F59E0B"), Color("#1E1B4B"))
	var tools_hbox = HBoxContainer.new()
	tools_hbox.name = "ToolsHBox"
	tools_hbox.add_theme_constant_override("separation", 6)

	badge_btn.pressed.connect(func():
		_dev_bar_expanded = not _dev_bar_expanded
		tools_hbox.visible = _dev_bar_expanded
		badge_btn.text = "🛠️ DEV [F12]" if _dev_bar_expanded else "🛠️ DEV ▸"
	)
	hbox.add_child(badge_btn)
	hbox.add_child(tools_hbox)

	for w in range(1, 7):
		var w_btn = _make_dev_btn("W%d" % w, Color("#C084FC") if w == 6 else Color("#38BDF8"), Color("#2E1065") if w == 6 else Color("#0F172A"))
		var world_idx = w
		w_btn.pressed.connect(func(): _dev_jump_to_world(world_idx))
		tools_hbox.add_child(w_btn)

	var unseal_btn = _make_dev_btn("🔓 Unseal & TP Boss", Color("#34D399"), Color("#064E3B"))
	unseal_btn.pressed.connect(_dev_trigger_unseal_and_tp)
	tools_hbox.add_child(unseal_btn)

	var boss_btn = _make_dev_btn("🐉 Boss Raid", Color("#FB7185"), Color("#4C0519"))
	boss_btn.pressed.connect(_dev_jump_to_boss_battle)
	tools_hbox.add_child(boss_btn)

	var solve_btn = _make_dev_btn("⚡ Solve Phase", Color("#FCD34D"), Color("#451A03"))
	solve_btn.pressed.connect(_dev_trigger_solve_phase)
	tools_hbox.add_child(solve_btn)

	var normal_btn = _make_dev_btn("✕ Normal Flow", Color("#CBD5E1"), Color("#1E293B"))
	normal_btn.pressed.connect(func(): set_dev_mode(false))
	tools_hbox.add_child(normal_btn)

func _make_dev_btn(txt: String, border_col: Color, bg_col: Color) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color("#F8FAFC"))
	var st = StyleBoxFlat.new()
	st.bg_color = bg_col
	st.border_color = border_col
	st.set_border_width_all(1)
	st.set_corner_radius_all(5)
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.content_margin_top = 3
	st.content_margin_bottom = 3
	btn.add_theme_stylebox_override("normal", st)
	var st_hover = st.duplicate() as StyleBoxFlat
	st_hover.bg_color = bg_col.lightened(0.18)
	btn.add_theme_stylebox_override("hover", st_hover)
	btn.add_theme_stylebox_override("pressed", st_hover)
	return btn

func _update_dev_overlay_visibility() -> void:
	if _dev_layer:
		_dev_layer.visible = dev_mode_enabled

func _dev_jump_to_world(world_num: int) -> void:
	user_profile["current_level"] = world_num
	match world_num:
		1: SceneManager.change_scene(SceneManager.WORLD_1)
		2: SceneManager.change_scene(SceneManager.WORLD_2)
		3: SceneManager.change_scene(SceneManager.WORLD_3)
		4: SceneManager.change_scene(SceneManager.WORLD_4)
		5: SceneManager.change_scene(SceneManager.WORLD_5)
		6: SceneManager.change_scene(SceneManager.WORLD_6)

func _dev_trigger_unseal_and_tp() -> void:
	var cur = get_tree().current_scene
	if cur and cur.has_method("dev_unseal_and_teleport_boss"):
		cur.dev_unseal_and_teleport_boss()

func _dev_jump_to_boss_battle() -> void:
	var cur = get_tree().current_scene
	if cur:
		var s_name = cur.name
		if s_name.begins_with("World"):
			var num_str = s_name.trim_prefix("World")
			if num_str.is_valid_int():
				user_profile["current_level"] = num_str.to_int()
	SceneManager.change_scene(SceneManager.LEVEL_GAMEPLAY)

func _dev_trigger_solve_phase() -> void:
	var cur = get_tree().current_scene
	if cur and cur.has_method("dev_auto_solve_phase"):
		cur.dev_auto_solve_phase()

func get_default_profile(is_guest_account: bool = true) -> Dictionary:
	return {
		"full_name": "Adventurer Alex",
		"is_guest": is_guest_account,
		"player_level": 1,
		"xp": 0,
		"unlocked_level": 1,
		"hint_tokens": 5,
		"current_level": 1,
		"level_stars": {
			"1": 0,
			"2": 0,
			"3": 0,
			"4": 0,
			"5": 0
		},
		"settings": {
			"master_volume": 1.0,
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"code_font_size": "medium",
			"screen_shake": true,
			"screen_flash": true,
			"show_joystick": true
		}
	}

# Check if current session is guest (offline phone storage only)
func is_guest() -> bool:
	return bool(user_profile.get("is_guest", false)) or not FirebaseManager.is_authenticated()

# Start or resume a local guest session
func start_guest_session() -> void:
	# Ensure any online session is disconnected
	if FirebaseManager.is_authenticated():
		FirebaseManager.logout()
		
	# If no local guest save exists yet, initialize default
	if not FileAccess.file_exists(GUEST_SAVE_PATH):
		user_profile = get_default_profile(true)
	else:
		load_local_profile(GUEST_SAVE_PATH)
	
	# Explicitly ensure guest flag and guest name are enforced
	user_profile["is_guest"] = true
	if user_profile.get("full_name", "") == "" or user_profile.get("full_name") == "Player":
		user_profile["full_name"] = "Adventurer Alex"
	save_local_profile()

# Saves user profile data locally on the device (phone storage)
func save_local_profile(custom_path: String = "") -> void:
	var path = custom_path if not custom_path.is_empty() else get_current_save_path()
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(user_profile, "  "))
		file.close()

# Alias for compatibility
func save_local_data() -> void:
	save_local_profile()

func save_profile() -> void:
	save_local_profile()

# Loads user profile data from local storage
func load_local_profile(custom_path: String = "") -> void:
	var path = custom_path if not custom_path.is_empty() else get_current_save_path()
	if not FileAccess.file_exists(path):
		# Fallback: check old legacy save file if guest save doesn't exist yet
		if is_guest() and FileAccess.file_exists("user://save_data.json"):
			path = "user://save_data.json"
		else:
			return

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var data = JSON.parse_string(content)
		if typeof(data) == TYPE_DICTIONARY:
			# Merge with defaults to ensure all required fields exist
			for k in data.keys():
				user_profile[k] = data[k]
			
			normalize_profile_data()

# Normalizes the user profile dictionary to prevent corrupt/mismatched data types (e.g. Firebase RTDB Array conversions)
func normalize_profile_data() -> void:
	# Ensure level_stars is always a valid Dictionary
	var raw_stars = user_profile.get("level_stars", {})
	var converted: Dictionary = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
	if typeof(raw_stars) == TYPE_DICTIONARY:
		for k in raw_stars.keys():
			converted[str(k)] = safe_int(raw_stars[k], 0)
	elif typeof(raw_stars) == TYPE_ARRAY:
		var arr: Array = raw_stars
		var is_one_indexed: bool = arr.size() > 0 and arr[0] == null
		for idx in range(arr.size()):
			var item = arr[idx]
			if item != null:
				var lvl_key = str(idx) if is_one_indexed else str(idx + 1)
				converted[lvl_key] = safe_int(item, 0)
	user_profile["level_stars"] = converted
	user_profile["unlocked_level"] = safe_int(user_profile.get("unlocked_level", 1), 1)

	# Ensure badges is an Array
	var raw_badges = user_profile.get("badges", [])
	if typeof(raw_badges) != TYPE_ARRAY:
		if typeof(raw_badges) == TYPE_DICTIONARY:
			user_profile["badges"] = raw_badges.values()
		else:
			user_profile["badges"] = []

	# Ensure badges_unlocked_at is a Dictionary
	var raw_times = user_profile.get("badges_unlocked_at", {})
	if typeof(raw_times) != TYPE_DICTIONARY:
		user_profile["badges_unlocked_at"] = {}

# Records progress when a level is completed
func record_level_completion(level_num: int, _added_score: int, added_xp: int, stars_earned: int) -> void:
	var current_xp = int(user_profile.get("xp", 0)) + added_xp
	user_profile["xp"] = current_xp
	
	# Recalculate player level: each 500 XP = 1 player level
	user_profile["player_level"] = max(1, int(current_xp / 500.0) + 1)
	
	# Unlock next level if currently on highest unlocked
	var unlocked = int(user_profile.get("unlocked_level", 1))
	if level_num >= unlocked and unlocked < 5:
		user_profile["unlocked_level"] = level_num + 1
		
	# Update star rating for level
	var stars_dict = user_profile.get("level_stars", {})
	if typeof(stars_dict) != TYPE_DICTIONARY:
		stars_dict = {}
	var prev_stars = int(stars_dict.get(str(level_num), 0))
	stars_dict[str(level_num)] = max(prev_stars, stars_earned)
	user_profile["level_stars"] = stars_dict
	
	# Always save to device's local phone storage
	save_local_profile()
	
	# ONLY sync to Firebase cloud database if user is logged into an online account
	if not is_guest() and FirebaseManager.is_authenticated():
		FirebaseManager.write_player_profile(user_profile)

	if Engine.has_singleton("BadgeManager") or get_node_or_null("/root/BadgeManager"):
		get_node("/root/BadgeManager").check_all_badges()

# Clears local cache for the active profile
func clear_profile() -> void:
	var path = get_current_save_path()
	user_profile = get_default_profile(is_guest())
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func get_setting(key: String, fallback = null):
	var settings = user_profile.get("settings", {})
	if typeof(settings) == TYPE_DICTIONARY and settings.has(key):
		return settings[key]
	return fallback

func set_setting(key: String, val) -> void:
	var settings = user_profile.get("settings", {})
	if typeof(settings) != TYPE_DICTIONARY:
		settings = {}
	settings[key] = val
	user_profile["settings"] = settings
	save_local_profile()
