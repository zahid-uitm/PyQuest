# res://scripts/ui/VirtualJoystick.gd
extends Control

signal joystick_vector_changed(vector: Vector2)

@onready var base_ring: Control = $BaseRing
@onready var knob: Control = $Knob

@export var max_distance: float = 60.0

var is_dragging: bool = false
var output_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	_reset_knob()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.is_pressed():
			is_dragging = true
			_update_joystick(event.position)
		else:
			is_dragging = false
			_reset_knob()
	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and is_dragging:
		_update_joystick(event.position)

func _update_joystick(touch_pos: Vector2) -> void:
	var center: Vector2 = base_ring.position + (base_ring.size / 2.0)
	var dir: Vector2 = touch_pos - center
	
	if dir.length() > max_distance:
		dir = dir.normalized() * max_distance
		
	knob.position = (base_ring.position + (base_ring.size / 2.0) - (knob.size / 2.0)) + dir
	output_vector = dir / max_distance
	joystick_vector_changed.emit(output_vector)

func _reset_knob() -> void:
	knob.position = base_ring.position + (base_ring.size / 2.0) - (knob.size / 2.0)
	output_vector = Vector2.ZERO
	joystick_vector_changed.emit(output_vector)
