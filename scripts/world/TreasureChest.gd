# res://scripts/world/TreasureChest.gd
extends Area2D

signal chest_opened(chest_id: String, xp_amount: int)

@export var chest_id: String = "chest_1"
@export var xp_reward: int = 25
@export var lore_title: String = "Secret Codex Entry"
@export var lore_text: String = "Variable names in Python can only contain letters, numbers, and underscores, and cannot start with a number!"
@export var is_opened: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label: Label = $PromptLabel
@onready var particles: CPUParticles2D = $SparkleParticles

var player_in_range: bool = false

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)
	
	# Check if previously opened
	var saved_chests = SaveManager.user_profile.get("opened_chests", [])
	if typeof(saved_chests) == TYPE_ARRAY and chest_id in saved_chests:
		is_opened = true
		sprite.frame = 3
		if prompt_label:
			prompt_label.text = "[E / Tap] Inspect Note"

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
			_trigger_chest()
	elif event.is_action_pressed("ui_accept"):
		_trigger_chest()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if player_in_range and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_trigger_chest()

func _trigger_chest() -> void:
	if not is_opened:
		is_opened = true
		AudioManager.play_chest_open()
		_play_open_animation()
		
		# Save opened state
		var chests = SaveManager.user_profile.get("opened_chests", [])
		if typeof(chests) != TYPE_ARRAY:
			chests = []
		if chest_id not in chests:
			chests.append(chest_id)
		SaveManager.user_profile["opened_chests"] = chests
		SaveManager.user_profile["chests_opened"] = chests
		BadgeManager.check_all_badges()
		
		# Award XP
		var cur_xp = int(SaveManager.user_profile.get("xp", 0)) + xp_reward
		SaveManager.user_profile["xp"] = cur_xp
		SaveManager.user_profile["player_level"] = max(1, int(cur_xp / 500) + 1)
		SaveManager.save_local_profile()
		
		if prompt_label:
			prompt_label.text = "[E / Tap] Inspect Note"
		
		chest_opened.emit(chest_id, xp_reward)
	
	var world = get_tree().current_scene
	if world and world.has_method("show_lore_modal"):
		world.show_lore_modal(lore_title, lore_text, xp_reward)

func _play_open_animation() -> void:
	if particles:
		particles.restart()
		particles.emitting = true
	
	var tween = create_tween()
	tween.tween_callback(func(): sprite.frame = 1)
	tween.tween_interval(0.1)
	tween.tween_callback(func(): sprite.frame = 2)
	tween.tween_interval(0.12)
	tween.tween_callback(func(): sprite.frame = 3)
