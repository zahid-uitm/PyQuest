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
	input_event.connect(_on_input_event)

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
	if not player_in_range:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.is_action_pressed("ui_accept"):
			_trigger_quest_dialog()
	elif event.is_action_pressed("ui_accept"):
		_trigger_quest_dialog()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if player_in_range and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_trigger_quest_dialog()

func _trigger_quest_dialog() -> void:
	var world = get_tree().current_scene
	if world and world.has_method("open_quest_dialog"):
		world.open_quest_dialog()
	elif world and world.has_method("start_quiz"):
		world.start_quiz(level_json_path)
