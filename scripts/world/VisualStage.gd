# res://scripts/world/VisualStage.gd
extends Node2D

@onready var alex: CharacterBody2D = $Alex
@onready var chest: Sprite2D = $TreasureChest/Sprite2D
@onready var chest_particles: CPUParticles2D = $TreasureChest/ChestParticles
@onready var pywizard: Node2D = $PyWizard
@onready var pywizard_sprite: Sprite2D = $PyWizard/Sprite2D
@onready var float_label: Label = $FloatingLabel

var alex_start_pos: Vector2 = Vector2(280, 680)
var chest_pos: Vector2 = Vector2(780, 680)

func _ready() -> void:
	if alex:
		alex.position = alex_start_pos
		alex.can_move = false
		if alex.has_node("Camera2D"):
			alex.get_node("Camera2D").enabled = false
		alex.play_anim("side_idle")
		alex.face_direction(false) # Face right towards chest
	
	if chest:
		chest.frame = 0
		
	if float_label:
		float_label.visible = false

	if chest_particles:
		chest_particles.emitting = false

# Live animation when player submits correct Python code
func play_correct_action(action_type: String, score_val: int, xp_val: int) -> void:
	# 1. Alex steps forward toward chest
	if alex:
		alex.play_anim("side_walk")
		var walk_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		walk_tween.tween_property(alex, "position:x", alex_start_pos.x + 180.0, 0.6)
		await walk_tween.finished
		
		# 2. Alex casts spell / attacks lock
		alex.play_anim("side_attack")
		await get_tree().create_timer(0.35).timeout

	# 3. Chest unlocks and pops open
	if chest:
		chest.frame = 1
		await get_tree().create_timer(0.15).timeout
		chest.frame = 2
		await get_tree().create_timer(0.15).timeout
		chest.frame = 3 # Glowing open chest

	if chest_particles:
		chest_particles.restart()
		chest_particles.emitting = true

	# 4. Floating XP / Score reward animation
	show_floating_text("+%d Score  +%d XP" % [score_val, xp_val], Color("#FBBF24"))
	
	# 5. Alex returns to idle position
	await get_tree().create_timer(0.6).timeout
	if alex:
		alex.play_anim("side_walk")
		alex.face_direction(true)
		var return_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		return_tween.tween_property(alex, "position:x", alex_start_pos.x, 0.5)
		await return_tween.finished
		alex.face_direction(false)
		alex.play_anim("side_idle")

# Live feedback when code has error
func play_incorrect_action() -> void:
	# Chest sparks with failure
	if chest:
		var chest_tween = create_tween()
		chest_tween.tween_property(chest, "modulate", Color(2.0, 0.3, 0.3), 0.1)
		chest_tween.tween_property(chest, "modulate", Color.WHITE, 0.2)

	# Alex recoils
	if alex and alex.has_method("perform_recoil"):
		alex.perform_recoil()

	show_floating_text("⚡ Syntax Error!", Color("#EF4444"))

func show_pywizard_hint() -> void:
	if pywizard:
		var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_property(pywizard, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(pywizard, "scale", Vector2(1.0, 1.0), 0.3)
	show_floating_text("🧙 PyWizard: Wisdom Shared!", Color("#60A5FA"))

func show_floating_text(msg: String, color: Color) -> void:
	if not float_label:
		return
	float_label.text = msg
	float_label.visible = true
	float_label.position = Vector2(alex_start_pos.x + 100, alex_start_pos.y - 120)
	float_label.modulate = color
	float_label.modulate.a = 1.0

	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(float_label, "position:y", alex_start_pos.y - 200, 1.2)
	tween.parallel().tween_property(float_label, "modulate:a", 0.0, 1.2)
	await tween.finished
	float_label.visible = false

func reset_stage() -> void:
	if chest:
		chest.frame = 0
	if alex:
		alex.position = alex_start_pos
		alex.face_direction(false)
		alex.play_anim("side_idle")

