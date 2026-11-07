# res://scripts/core/SaveManager.gd
extends Node

const SAVE_PATH: String = "user://save_data.json"

# Active player profile dictionary used globally across the game
var user_profile: Dictionary = {
	"full_name": "Adventurer Alex",
	"is_guest": true,
	"player_level": 1,
	"xp": 0,
	"unlocked_level": 4,
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
	# If no local save exists yet, initialize default
	if not FileAccess.file_exists(SAVE_PATH):
		user_profile = get_default_profile(true)
	else:
		load_local_profile()
	
	# Explicitly ensure guest flag is set
	user_profile["is_guest"] = true
	save_local_profile()

# Saves user profile data locally on the device (phone storage)
func save_local_profile() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(user_profile, "  "))
		file.close()

# Alias for compatibility
func save_local_data() -> void:
	save_local_profile()

# Loads user profile data from local storage
func load_local_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var data = JSON.parse_string(content)
		if typeof(data) == TYPE_DICTIONARY:
			# Merge with defaults to ensure all required fields exist
			for k in data.keys():
				user_profile[k] = data[k]
			
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
			user_profile["unlocked_level"] = max(int(user_profile.get("unlocked_level", 1)), 4)

# Records progress when a level is completed
func record_level_completion(level_num: int, added_score: int, added_xp: int, stars_earned: int) -> void:
	var current_xp = int(user_profile.get("xp", 0)) + added_xp
	user_profile["xp"] = current_xp
	
	# Recalculate player level: each 500 XP = 1 player level
	user_profile["player_level"] = max(1, int(current_xp / 500) + 1)
	
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

# Clears local cache
func clear_profile() -> void:
	user_profile = get_default_profile(true)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

# Sets all stats to maximum: all 4 levels unlocked, 3 stars each, level 10, 5000 XP, 99 hint tokens, all shrines awakened and all bosses playable
func max_out_profile() -> void:
	user_profile["unlocked_level"] = 4
	user_profile["player_level"] = 10
	user_profile["xp"] = 5000
	user_profile["hint_tokens"] = 99
	user_profile["current_level"] = 4
	user_profile["level_stars"] = {
		"1": 3,
		"2": 3,
		"3": 3,
		"4": 3,
		"5": 3
	}

	# World 1: All Shrines Awakened & All NPCs Consulted
	user_profile["w1_shrines"] = ["shrine_numbers", "shrine_strings", "shrine_booleans"]
	user_profile["w1_npcs"] = ["npc_farmer_bob", "npc_blacksmith_dan", "npc_alchemist_elena"]

	# World 2: All Shrines Awakened, All Chasm Bridges Unsealed, All NPCs Consulted
	user_profile["w2_shrines"] = ["shrine_if_else", "shrine_for_loops", "shrine_while_loops"]
	user_profile["w2_bridges"] = ["bridge_chasm_left", "bridge_chasm_right"]
	user_profile["w2_npcs_helped"] = ["npc_keeper_venn", "npc_weaver_sera", "npc_sentinel_kael"]

	# World 3: All Shrines Awakened, All Vault Seals Broken, All NPCs Consulted
	user_profile["w3_shrines"] = ["shrine_def", "shrine_params", "shrine_return"]
	user_profile["w3_seals"] = ["seal_west", "seal_east"]
	user_profile["w3_npcs_helped"] = ["npc_archivist_def", "npc_artificer_param", "npc_oracle_ret"]

	# World 4: All Shrines Awakened, All Crypt Portcullis Gates Raised, All Relics Collected, All NPCs Consulted
	user_profile["w4_shrines"] = ["shrine_indexing", "shrine_mutation", "shrine_sequences"]
	user_profile["w4_gates"] = ["gate_west", "gate_east"]
	user_profile["w4_inventory"] = ["skull_key", "jade_urn", "soul_gem"]
	user_profile["w4_npcs_helped"] = ["npc_curator_idx", "npc_warden_mut", "npc_seers_seq"]

	save_local_profile()
	if not is_guest() and FirebaseManager.is_authenticated():
		FirebaseManager.write_player_profile(user_profile)

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
