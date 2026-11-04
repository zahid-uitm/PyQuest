# res://scripts/world/ValleyNPC.gd
extends Area2D

@export var npc_id: String = "npc_farmer_bob"
@export var npc_name: String = "Farmer Bob"
@export var npc_role: String = "Harvest Variable Keeper"
@export var npc_sheet: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel
@onready var quest_marker: Label = $QuestMarker
@onready var prompt_label: Label = $InteractionPrompt

var player_in_range: bool = false
var anim_timer: float = 0.0
var is_rewarded: bool = false

func _ready() -> void:
	if npc_sheet and sprite:
		sprite.texture = npc_sheet
		sprite.hframes = 6
		sprite.frame = 0
	if name_label:
		name_label.text = npc_name
	if prompt_label:
		prompt_label.visible = false
		
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)

func _process(delta: float) -> void:
	anim_timer += delta
	if sprite and sprite.hframes >= 6:
		sprite.frame = int(anim_timer * 5.0) % 6
	if quest_marker:
		quest_marker.position.y = -52.0 + sin(anim_timer * 4.0) * 2.5

func set_rewarded(rewarded: bool) -> void:
	is_rewarded = rewarded
	if quest_marker:
		if is_rewarded:
			quest_marker.text = "💬"
			quest_marker.modulate = Color(0.5, 0.9, 1.0, 0.85)
		else:
			quest_marker.text = "❗"
			quest_marker.modulate = Color(1.0, 0.85, 0.2, 1.0)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		if prompt_label:
			prompt_label.text = "[E] Talk to %s" % npc_name
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
			_trigger_npc()
	elif event.is_action_pressed("ui_accept"):
		_trigger_npc()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if player_in_range and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_trigger_npc()

func _trigger_npc() -> void:
	var world = get_tree().current_scene
	if world and world.has_method("open_npc_dialog"):
		world.open_npc_dialog(npc_id)
