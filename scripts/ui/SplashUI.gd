# res://scripts/ui/SplashUI.gd
extends Control

@onready var progress_bar: ProgressBar = $Container/ProgressBar

func _ready() -> void:
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 100.0, 2.0)
	tween.finished.connect(_on_loading_complete)

func _on_loading_complete() -> void:
	if FirebaseManager.is_authenticated():
		SceneManager.change_scene(SceneManager.MAIN_MENU)
	else:
		SceneManager.change_scene(SceneManager.LOGIN)
