# res://scripts/ui/MainMenuUI.gd
extends Control

@onready var user_name_label: Label = $HangingSignboard/WoodPlank/PlankVBox/UserNameLabel
@onready var level_label: Label = $HangingSignboard/WoodPlank/PlankVBox/LevelLabel
@onready var xp_progress_bar: ProgressBar = $HangingSignboard/WoodPlank/PlankVBox/XPContainer/XPProgressBar
@onready var hanging_signboard: Control = get_node_or_null("HangingSignboard")
@onready var title_logo: TextureRect = get_node_or_null("TitleLogo")

func _ready() -> void:
	AudioManager.play_bgm_by_path("res://pyquest_audio_mainmenu.mp3", 0.01)
	update_dashboard()
	_start_hanging_sign_sway()
	_start_title_bob()

func _start_title_bob() -> void:
	if not title_logo:
		return
	var base_y: float = title_logo.position.y
	var bob_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob_tween.tween_property(title_logo, "position:y", base_y - 6.0, 2.2)
	bob_tween.tween_property(title_logo, "position:y", base_y + 6.0, 2.2)

func _start_hanging_sign_sway() -> void:
	if not hanging_signboard:
		return
	
	# Set pivot at top center so the sign physically swings like a pendulum from its hanging ropes
	hanging_signboard.pivot_offset = Vector2(hanging_signboard.size.x * 0.5, 0.0)
	
	# Prominent, natural pendulum swing like PvZ hanging wooden sign
	var sway_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway_tween.tween_property(hanging_signboard, "rotation", 0.065, 2.0)
	sway_tween.tween_property(hanging_signboard, "rotation", -0.065, 2.0)

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
