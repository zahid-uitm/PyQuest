# res://scripts/world/World2D.gd
extends Node2D

@onready var player: CharacterBody2D = %Player
@onready var joystick: Control = %VirtualJoystick
@onready var quiz_ui: Control = %LevelGameplay

func _ready() -> void:
	quiz_ui.visible = false
	if player.has_method("set_joystick"):
		player.set_joystick(joystick)

func start_quiz(json_path: String) -> void:
	player.can_move = false
	joystick.visible = false
	quiz_ui.visible = true
	
	if quiz_ui.has_method("load_level_json"):
		quiz_ui.load_level_json(json_path)

func close_quiz() -> void:
	quiz_ui.visible = false
	joystick.visible = true
	player.can_move = true
