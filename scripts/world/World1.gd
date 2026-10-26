# res://scripts/world/World1.gd
extends Node2D

@onready var player: CharacterBody2D = %Player
@onready var joystick: Control = %VirtualJoystick
@onready var quest_dialog: Control = %QuestDialogModal
@onready var quest_text: Label = %QuestText
@onready var accept_btn: Button = %AcceptButton
@onready var decline_btn: Button = %DeclineButton
@onready var hud_back_btn: Button = %BackToSelectButton
@onready var area_title_label: Label = %AreaTitleLabel

func _ready() -> void:
	if quest_dialog:
		quest_dialog.visible = false
	if player and player.has_method("set_joystick"):
		player.set_joystick(joystick)
		
	if accept_btn and not accept_btn.pressed.is_connected(_on_accept_quest):
		accept_btn.pressed.connect(_on_accept_quest)
	if decline_btn and not decline_btn.pressed.is_connected(_on_close_quest_dialog):
		decline_btn.pressed.connect(_on_close_quest_dialog)
	if hud_back_btn and not hud_back_btn.pressed.is_connected(_on_back_to_select):
		hud_back_btn.pressed.connect(_on_back_to_select)

	var p_name = SaveManager.user_profile.get("full_name", "Adventurer Alex")
	if area_title_label:
		area_title_label.text = "📍 Chapter 1: Variable Valley  |  Adventurer: %s" % p_name

func open_quest_dialog() -> void:
	if player:
		player.can_move = false
	if joystick:
		joystick.visible = false
		
	var stars = int(SaveManager.user_profile.get("level_stars", {}).get("1", 0))
	if stars > 0:
		var stars_str = ""
		for s in range(3):
			stars_str += "★" if s < stars else "☆"
		quest_text.text = "Greetings, Alex!\nYou have conquered Variable Valley (%s).\n\nWould you like to re-enter the trial to sharpen your skills and improve your score?" % stars_str
		accept_btn.text = "⚔️ Replay Quest"
	else:
		quest_text.text = "Greetings, Adventurer Alex!\n\nWelcome to Variable Valley. The ancient chambers require mastery of Python variables, data types, and syntax to unlock.\n\nWill you accept this quest and begin the trial?"
		accept_btn.text = "⚔️ Accept Quest"

	if quest_dialog:
		quest_dialog.visible = true

func _on_accept_quest() -> void:
	SaveManager.user_profile["current_level"] = 1
	SaveManager.save_local_profile()
	SceneManager.change_scene(SceneManager.LEVEL_GAMEPLAY)

func _on_close_quest_dialog() -> void:
	if quest_dialog:
		quest_dialog.visible = false
	if player:
		player.can_move = true
	if joystick:
		joystick.visible = true

func _on_back_to_select() -> void:
	SceneManager.change_scene(SceneManager.LEVEL_SELECT)

