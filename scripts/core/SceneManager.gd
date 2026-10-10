# res://scripts/core/SceneManager.gd
extends Node

const SPLASH = "res://scenes/ui/Splash.tscn"
const LOGIN = "res://scenes/ui/Login.tscn"
const SIGN_UP = "res://scenes/ui/SignUp.tscn"
const MAIN_MENU = "res://scenes/ui/MainMenu.tscn"
const LEVEL_SELECT = "res://scenes/ui/LevelSelect.tscn"
const LEVEL_GAMEPLAY = "res://scenes/ui/LevelGameplay.tscn"

func change_scene(scene_path: String) -> void:
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneManager: Failed to load scene: %s" % scene_path)
