# res://scripts/core/SaveManager.gd
extends Node

const SAVE_PATH: String = "user://save_data.json"

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
	}
}

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
	var prev_stars = int(stars_dict.get(str(level_num), 0))
	stars_dict[str(level_num)] = max(prev_stars, stars_earned)
	user_profile["level_stars"] = stars_dict
	
	# Always save to device's local phone storage
	save_local_profile()
	
	# ONLY sync to Firebase cloud database if user is logged into an online account
	if not is_guest() and FirebaseManager.is_authenticated():
		FirebaseManager.write_player_profile(user_profile)

# Clears local cache
func clear_profile() -> void:
	user_profile = get_default_profile(true)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
