# res://scripts/ui/MainMenuUI.gd
extends Control

@onready var user_name_label: Label = $Header/UserNameLabel
@onready var xp_progress_bar: ProgressBar = $Header/XPProgressBar
@onready var level_label: Label = $Header/LevelLabel

func _ready() -> void:
	update_dashboard()

func update_dashboard() -> void:
	var profile = SaveManager.user_profile
	user_name_label.text = "Welcome back, %s!" % profile.get("full_name", "Alex")[cite: 57]
	level_label.text = "Level %d" % profile.get("player_level", 1)[cite: 57]
	
	var current_xp = profile.get("xp", 0)[cite: 57]
	xp_progress_bar.value = current_xp % 500
	xp_progress_bar.max_value = 500

func _on_continue_quest_pressed() -> void:
	SceneManager.change_scene(SceneManager.LEVEL_SELECT)

func _on_level_select_pressed() -> void:
	SceneManager.change_scene(SceneManager.LEVEL_SELECT)

func _on_logout_pressed() -> void:
	FirebaseManager.logout()
	SceneManager.change_scene(SceneManager.LOGIN)
