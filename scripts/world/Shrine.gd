# res://scripts/world/Shrine.gd
extends Area2D

signal shrine_interacted(shrine_node: Area2D)

@export var shrine_id: String = "shrine_numbers"
@export var shrine_title: String = "Shrine of Numbers"
@export var concept_title: String = "Variables & Numbers"
@export var rune_color: Color = Color(0.2, 0.7, 1.0, 1.0)
@export var is_activated: bool = false

@onready var prompt_label: Label = $PromptLabel
@onready var title_label: Label = $TitleLabel
@onready var rune_light: Sprite2D = $RuneGlow
@onready var particles: CPUParticles2D = $Particles

var player_in_range: bool = false
var glow_tween: Tween

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	if title_label:
		title_label.text = "✦ " + shrine_title
		title_label.modulate = rune_color
	if rune_light:
		rune_light.modulate = rune_color
		
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)
	
	_start_glow_animation()
	update_visual_state()

func _start_glow_animation() -> void:
	if not rune_light:
		return
	glow_tween = create_tween().set_loops()
	glow_tween.tween_property(rune_light, "scale", Vector2(1.2, 1.2), 1.2).set_trans(Tween.TRANS_SINE)
	glow_tween.tween_property(rune_light, "scale", Vector2(0.9, 0.9), 1.2).set_trans(Tween.TRANS_SINE)

func update_visual_state() -> void:
	if is_activated:
		if rune_light:
			rune_light.modulate = rune_color * 1.5
			rune_light.visible = true
		if particles:
			particles.emitting = true
			particles.color = rune_color
		if prompt_label:
			prompt_label.text = "[E / Tap] Review Codex ✓"
	else:
		if rune_light:
			rune_light.modulate = Color(rune_color.r * 0.4, rune_color.g * 0.4, rune_color.b * 0.4, 0.6)
		if particles:
			particles.emitting = false
		if prompt_label:
			prompt_label.text = "[E / Tap] Attune Shrine"

func set_activated(active: bool) -> void:
	is_activated = active
	update_visual_state()
	if active and particles:
		particles.restart()
		particles.emitting = true

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
			_trigger_shrine()
	elif event.is_action_pressed("ui_accept"):
		_trigger_shrine()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if player_in_range and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_trigger_shrine()

func _trigger_shrine() -> void:
	var world = get_tree().current_scene
	if world and world.has_method("open_shrine_dialog"):
		world.open_shrine_dialog(shrine_id)
	shrine_interacted.emit(self)

