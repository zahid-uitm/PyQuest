# res://scripts/ui/PauseModal.gd
extends ColorRect

signal paused
signal resumed
signal respawn_requested
signal return_to_map_requested

@onready var pause_card: PanelContainer = %PauseCard
@onready var resume_btn: Button = %ResumeButton
@onready var restart_btn: Button = %RestartButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton
@onready var settings_modal: ColorRect = %SettingsModal

var is_active: bool = false

func _ready() -> void:
	visible = false
	if settings_modal:
		settings_modal.visible = false
		if not settings_modal.settings_closed.is_connected(_on_settings_closed):
			settings_modal.settings_closed.connect(_on_settings_closed)

	if resume_btn:
		resume_btn.pressed.connect(close_pause)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)

func open_pause() -> void:
	is_active = true
	visible = true
	if settings_modal:
		settings_modal.visible = false

	if pause_card:
		pause_card.scale = Vector2(0.85, 0.85)
		pause_card.pivot_offset = pause_card.size * 0.5
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(pause_card, "scale", Vector2.ONE, 0.22)

	paused.emit()

func close_pause() -> void:
	is_active = false
	visible = false
	if settings_modal:
		settings_modal.visible = false
	resumed.emit()

func is_paused() -> bool:
	return is_active and visible

func _on_restart_pressed() -> void:
	close_pause()
	respawn_requested.emit()

func _on_settings_pressed() -> void:
	if settings_modal and settings_modal.has_method("open_settings"):
		settings_modal.open_settings()

func _on_settings_closed() -> void:
	if is_active:
		visible = true

func _on_quit_pressed() -> void:
	is_active = false
	visible = false
	return_to_map_requested.emit()
	SceneManager.change_scene(SceneManager.LEVEL_SELECT)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_modal and settings_modal.visible:
			return
		if visible:
			close_pause()
			get_viewport().set_input_as_handled()
