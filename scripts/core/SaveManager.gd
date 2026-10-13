# res://scripts/core/SaveManager.gd
extends Node

# Active player profile dictionary used globally across the game
var user_profile: Dictionary = {
	"full_name": "",
	"player_level": 1,
	"xp": 0,
	"unlocked_level": 1,
	"hint_tokens": 5
}

const SAVE_PATH: String = "user://save_data.json"

# Saves user profile data locally on the device (for offline cache)
func save_local_profile() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(user_profile))
		file.close()

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
			user_profile = data

# Clears local cache on logout
func clear_profile() -> void:
	user_profile = {}
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
