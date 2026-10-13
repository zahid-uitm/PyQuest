# res://scripts/ui/MainMenuUI.gd
extends Control

@onready var user_name_label: Label = $Header/UserNameLabel
@onready var xp_progress_bar: ProgressBar = $Header/XPProgressBar
@onready var level_label: Label = $Header/LevelLabel

func _ready() -> void:
	update_dashboard()

func update_dashboard() -> void:
	var profile: Dictionary = SaveManager.user_profile
	
	user_name_label.text = "Welcome back, %s!" % profile.get("full_name", "Player")
	level_label.text = "Level %d" % int(profile.get("player_level", 1))
	
	var current_xp: int = int(profile.get("xp", 0))
	xp_progress_bar.value = current_xp % 500
	xp_progress_bar.max_value = 500

func _on_continue_quest_button_pressed() -> void:
	SceneManager.change_scene(SceneManager.LEVEL_SELECT)

func _on_level_select_button_pressed() -> void:
	SceneManager.change_scene(SceneManager.LEVEL_SELECT)

func _on_logout_button_pressed() -> void:
	FirebaseManager.logout()
	SceneManager.change_scene(SceneManager.LOGIN)
