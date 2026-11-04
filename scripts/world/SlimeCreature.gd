# res://scripts/world/SlimeCreature.gd
extends Area2D

@export var slime_name: String = "Moss Slime"
@export var quote_text: String = "Boing! Did you know? Variables store data in memory!"
@export var wander_radius: float = 60.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var speech_bubble: PanelContainer = $SpeechBubble
@onready var speech_label: Label = $SpeechBubble/Margin/SpeechLabel

var spawn_pos: Vector2
var base_scale: Vector2 = Vector2(2.1, 2.1)
var is_moving: bool = false
var bubble_timer: float = 0.0

func _ready() -> void:
	spawn_pos = position
	if speech_bubble:
		speech_bubble.visible = false
		speech_label.text = quote_text
	
	if sprite:
		base_scale = sprite.scale
		sprite.play("idle")
		
	input_event.connect(_on_input_event)
	body_entered.connect(_on_body_entered)
	
	# Start autonomous hop loop
	_schedule_next_hop()

func _schedule_next_hop() -> void:
	var delay = randf_range(2.5, 5.0)
	get_tree().create_timer(delay).timeout.connect(_do_hop)

func _do_hop() -> void:
	if not is_inside_tree() or is_moving:
		return
		
	# Pick random target within wander_radius
	var offset = Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	var target = spawn_pos + offset
	
	# Determine direction
	var dir = (target - position).normalized()
	if dir.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
		
	is_moving = true
	sprite.play("hop")
	
	var tween = create_tween()
	# Arc motion: jump Y then land
	tween.tween_property(self, "position", target, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "scale", base_scale * Vector2(1.2, 0.8), 0.15)
	tween.parallel().tween_property(sprite, "scale", base_scale * Vector2(0.9, 1.2), 0.3).set_delay(0.15)
	tween.parallel().tween_property(sprite, "scale", base_scale, 0.15).set_delay(0.45)
	
	tween.finished.connect(func():
		is_moving = false
		if sprite:
			sprite.play("idle")
		_schedule_next_hop()
	)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_pop_squish()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pop_squish()

func _pop_squish() -> void:
	# Cute squish reaction
	var squish = create_tween()
	squish.tween_property(sprite, "scale", base_scale * Vector2(1.3, 0.7), 0.1)
	squish.tween_property(sprite, "scale", base_scale * Vector2(0.8, 1.2), 0.12)
	squish.tween_property(sprite, "scale", base_scale, 0.1)
	
	_show_bubble()

func _show_bubble() -> void:
	if not speech_bubble:
		return
	speech_bubble.visible = true
	speech_bubble.scale = Vector2.ZERO
	speech_bubble.pivot_offset = speech_bubble.size * 0.5
	
	var pop = create_tween()
	pop.tween_property(speech_bubble, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_interval(3.0)
	pop.tween_property(speech_bubble, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	pop.tween_callback(func(): speech_bubble.visible = false)
