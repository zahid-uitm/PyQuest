# res://scripts/ui/SplashUI.gd
extends Control

@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel

var loading_messages: Array[String] = [
	"Initializing quest engine...",
	"Loading Python syntax modules...",
	"Synchronizing quest archives...",
	"Preparing your adventure..."
]

func _ready() -> void:
	progress_bar.value = 0.0
	run_splash_sequence()

func run_splash_sequence() -> void:
	# 1. Subtle delay to let wallpaper display
	await get_tree().create_timer(0.4).timeout

	# 2. Animate Progress Bar loading
	var progress_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	progress_tween.tween_property(progress_bar, "value", 100.0, 2.5)
	
	# Cycle status messages in parallel with the progress bar
	var step_time: float = 2.5 / float(loading_messages.size())
	for msg in loading_messages:
		status_label.text = msg
		await get_tree().create_timer(step_time).timeout

	# Force progress bar to 100% just in case
	progress_bar.value = 100.0
	await get_tree().create_timer(0.2).timeout

	# 3. Route user based on authentication status
	if FirebaseManager.is_authenticated():
		SceneManager.change_scene(SceneManager.MAIN_MENU)
	else:
		SceneManager.change_scene(SceneManager.LOGIN)
