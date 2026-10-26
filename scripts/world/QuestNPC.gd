# res://scripts/world/QuestNPC.gd
extends Area2D

@export var level_json_path: String = "res://data/question_level1.json"
@onready var prompt_label: Label = $InteractionPrompt

var player_in_range: bool = false

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("ui_accept"):
		var world = get_tree().current_scene
		if world.has_method("start_quiz"):
			world.start_quiz(level_json_path)
