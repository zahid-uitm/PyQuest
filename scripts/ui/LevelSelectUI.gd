# res://scripts/ui/LevelSelectUI.gd
extends Control

@onready var level1_button: Button = $QuestMap/Level1Card/EnterButton
@onready var level2_button: Button = $QuestMap/Level2Card/EnterButton

func _ready() -> void:
	setup_level_cards()

func setup_level_cards() -> void:
	var unlocked_level = SaveManager.user_profile.get("unlocked_level", 1)
	
	level1_button.disabled = false
	level1_button.pressed.connect(func(): start_level(1))
	
	if unlocked_level >= 2:
		level2_button.disabled = false
		level2_button.text = "Enter ->"
		level2_button.pressed.connect(func(): start_level(2))
	else:
		level2_button.disabled = true
		level2_button.text = "Locked"[cite: 57]

func start_level(level_num: int) -> void:
	GameManager.current_level = level_num
	SceneManager.change_scene(SceneManager.LEVEL_GAMEPLAY)
