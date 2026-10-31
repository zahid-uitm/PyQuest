# res://scripts/ui/MainMenuUI.gd
extends Control

@onready var user_name_label: Label = $HeaderPanel/HeaderContainer/UserInfo/UserNameLabel
@onready var level_label: Label = $HeaderPanel/HeaderContainer/UserInfo/LevelLabel
@onready var xp_progress_bar: ProgressBar = $HeaderPanel/HeaderContainer/XPContainer/XPProgressBar

func _ready() -> void:
	update_dashboard()

func update_dashboard() -> void:
	var profile: Dictionary = SaveManager.user_profile
	
	var raw_name: String = profile.get("full_name", "Player")
	var current_level: int = int(profile.get("player_level", 1))
	
	if SaveManager.is_guest():
		user_name_label.text = "⚔️ %s (Guest)" % raw_name
		level_label.text = "Level %d Adventurer • Local Device Storage" % current_level
	else:
		user_name_label.text = "Welcome back, %s!" % raw_name
		level_label.text = "Level %d Adventurer • Cloud Sync Active" % current_level
	
	var current_xp: int = int(profile.get("xp", 0))
	var xp_in_level: int = current_xp % 500
	
	xp_progress_bar.max_value = 500
	
	# Smoothly animate XP progress bar load
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(xp_progress_bar, "value", xp_in_level, 0.8)

func _on_continue_quest_button_pressed() -> void:
	var unlocked: int = int(SaveManager.user_profile.get("unlocked_level", 1))
	SaveManager.user_profile["current_level"] = unlocked
	SceneManager.change_scene(SceneManager.WORLD_1)

func _on_level_select_button_pressed() -> void:
	SceneManager.change_scene(SceneManager.LEVEL_SELECT)

func _on_logout_button_pressed() -> void:
	FirebaseManager.logout()
	SceneManager.change_scene(SceneManager.LOGIN)
