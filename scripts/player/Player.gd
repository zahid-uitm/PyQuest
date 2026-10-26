# res://scripts/player/Player.gd
extends CharacterBody2D

@export var speed: float = 250.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var joystick_vector: Vector2 = Vector2.ZERO
var can_move: bool = true
var last_facing: String = "front" # Tracks "front", "back", or "side"

func set_joystick(joystick_node: Node) -> void:
	if joystick_node and joystick_node.has_signal("joystick_vector_changed"):
		# Prevent duplicate signal connections
		if not joystick_node.joystick_vector_changed.is_connected(_on_joystick_vector_changed):
			joystick_node.joystick_vector_changed.connect(_on_joystick_vector_changed)

func _on_joystick_vector_changed(vector: Vector2) -> void:
	joystick_vector = vector

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		_update_animation(Vector2.ZERO)
		move_and_slide()
		return

	# Combine Keyboard (WASD / Arrow Keys) + Touch Joystick input
	var keyboard_input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var move_dir: Vector2 = keyboard_input + joystick_vector

	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()

	velocity = move_dir * speed
	move_and_slide()

	# Update sprite animations based on final movement vector
	_update_animation(move_dir)

func _update_animation(move_dir: Vector2) -> void:
	if not sprite:
		return

	# Deadzone check: Player is moving
	if move_dir.length() > 0.1:
		if abs(move_dir.x) > abs(move_dir.y):
			# Horizontal movement (Left / Right)
			last_facing = "side"
			sprite.play("side_walk")
			sprite.flip_h = (move_dir.x < 0) # Flip sprite left when x is negative
		elif move_dir.y > 0:
			# Downward movement
			last_facing = "front"
			sprite.play("front_walk")
			sprite.flip_h = false
		elif move_dir.y < 0:
			# Upward movement
			last_facing = "back"
			sprite.play("back_walk")
			sprite.flip_h = false
	else:
		# Player is stationary (Play Idle in the last facing direction)
		match last_facing:
			"side":
				sprite.play("side_idle")
			"back":
				sprite.play("back_idle")
			"front", _:
				sprite.play("front_idle")
