# res://scripts/core/SceneManager.gd
extends Node

const SPLASH = "res://scenes/ui/Splash.tscn"
const LOGIN = "res://scenes/ui/Login.tscn"
const SIGN_UP = "res://scenes/ui/SignUp.tscn"
const MAIN_MENU = "res://scenes/ui/MainMenu.tscn"
const LEVEL_SELECT = "res://scenes/ui/LevelSelect.tscn"
const LEVEL_GAMEPLAY = "res://scenes/ui/LevelGameplay.tscn"
const WORLD_1 = "res://scenes/world/World1.tscn"
const WORLD_2 = "res://scenes/world/World2.tscn"
const WORLD_3 = "res://scenes/world/World3.tscn"
const WORLD_4 = "res://scenes/world/World4.tscn"
const WORLD_5 = "res://scenes/world/World5.tscn"
const WORLD_6 = "res://scenes/world/World6.tscn"
const CINEMATIC_INTRO = "res://scenes/ui/CinematicIntro.tscn"
const CUTSCENE_PLOT_TWIST = "res://scenes/ui/CutscenePlotTwist.tscn"
const CUTSCENE_THRONE = "res://scenes/ui/CutsceneThrone.tscn"
const CUTSCENE_EPILOGUE = "res://scenes/ui/CutsceneEpilogue.tscn"
const GAMEPLAY = "res://scenes/world/World1.tscn"
const LOADING_SCREEN = "res://scenes/ui/LoadingScreen.tscn"

var target_scene_path: String = ""
var target_custom_data: Dictionary = {}
var loading_wallpaper_bag: Array[String] = []
var last_loading_wallpaper: String = ""

func get_next_loading_wallpaper(available_wallpapers: Array[String]) -> String:
	# Filter bag to only include currently available wallpapers
	var valid_bag: Array[String] = []
	for path in loading_wallpaper_bag:
		if path in available_wallpapers:
			valid_bag.append(path)
	loading_wallpaper_bag = valid_bag
	
	# If deck is exhausted, create a new deck with all available wallpapers and shuffle
	if loading_wallpaper_bag.is_empty():
		var new_deck = available_wallpapers.duplicate()
		new_deck.shuffle()
		# Prevent immediate repeat between the end of one deck and the start of the next
		if new_deck.size() > 1 and new_deck[0] == last_loading_wallpaper:
			var first = new_deck.pop_front()
			new_deck.append(first)
		loading_wallpaper_bag = new_deck
	
	var chosen = loading_wallpaper_bag.pop_front()
	last_loading_wallpaper = chosen
	return chosen

func change_scene(scene_path: String) -> void:
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneManager: Failed to load scene: %s" % scene_path)

func change_scene_with_loading(scene_path: String, custom_data: Dictionary = {}) -> void:
	target_scene_path = scene_path
	target_custom_data = custom_data
	var error = get_tree().change_scene_to_file(LOADING_SCREEN)
	if error != OK:
		push_error("SceneManager: Failed to open loading screen, falling back to direct load: %s" % scene_path)
		get_tree().change_scene_to_file(scene_path)
