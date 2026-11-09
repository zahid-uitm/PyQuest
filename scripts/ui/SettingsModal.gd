# res://scripts/ui/SettingsModal.gd
extends ColorRect

signal settings_closed

# Tab Buttons
@onready var tab_audio_btn: Button = %TabAudioBtn
@onready var tab_visuals_btn: Button = %TabVisualsBtn
@onready var tab_controls_btn: Button = %TabControlsBtn

# Tab Containers
@onready var panel_audio: VBoxContainer = %PanelAudio
@onready var panel_visuals: VBoxContainer = %PanelVisuals
@onready var panel_controls: VBoxContainer = %PanelControls

# Audio Controls
@onready var master_slider: HSlider = %MasterSlider
@onready var master_val_label: Label = %MasterValLabel
@onready var music_slider: HSlider = %MusicSlider
@onready var music_val_label: Label = %MusicValLabel
@onready var sfx_slider: HSlider = %SFXSlider
@onready var sfx_val_label: Label = %SFXValLabel
@onready var test_sfx_btn: Button = %TestSFXBtn

# Visuals Controls
@onready var font_small_btn: Button = %FontSmallBtn
@onready var font_med_btn: Button = %FontMedBtn
@onready var font_large_btn: Button = %FontLargeBtn
@onready var code_preview_label: RichTextLabel = %CodePreviewLabel
@onready var check_shake: CheckBox = %CheckShake
@onready var check_flash: CheckBox = %CheckFlash
@onready var check_fullscreen: CheckBox = %CheckFullscreen

# Controls & Data
@onready var check_joystick: CheckBox = %CheckJoystick
@onready var check_dev_mode: CheckBox = get_node_or_null("%CheckDevMode")
@onready var account_status_label: Label = %AccountStatusLabel
@onready var logout_btn: Button = %LogoutBtn
@onready var reset_progress_btn: Button = %ResetProgressBtn
@onready var close_btn: Button = %CloseBtn

# Reset Confirm Dialog
@onready var reset_confirm_modal: ColorRect = %ResetConfirmModal
@onready var confirm_reset_btn: Button = %ConfirmResetBtn
@onready var cancel_reset_btn: Button = %CancelResetBtn

var active_tab: int = 0 # 0: Audio, 1: Visuals, 2: Controls

func _ready() -> void:
	visible = false
	if reset_confirm_modal:
		reset_confirm_modal.visible = false

	# Connect Tabs
	tab_audio_btn.pressed.connect(func(): _switch_tab(0))
	tab_visuals_btn.pressed.connect(func(): _switch_tab(1))
	tab_controls_btn.pressed.connect(func(): _switch_tab(2))

	# Connect Close
	close_btn.pressed.connect(close_settings)

	# Connect Audio Sliders
	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	test_sfx_btn.pressed.connect(_on_test_sfx_pressed)

	# Connect Visuals
	font_small_btn.pressed.connect(func(): _set_code_font_size("small"))
	font_med_btn.pressed.connect(func(): _set_code_font_size("medium"))
	font_large_btn.pressed.connect(func(): _set_code_font_size("large"))
	check_shake.toggled.connect(_on_shake_toggled)
	check_flash.toggled.connect(_on_flash_toggled)
	check_fullscreen.toggled.connect(_on_fullscreen_toggled)

	# Connect Controls & Account
	check_joystick.toggled.connect(_on_joystick_toggled)
	if check_dev_mode:
		check_dev_mode.toggled.connect(_on_dev_mode_toggled)
	if SaveManager.has_signal("dev_mode_changed"):
		SaveManager.dev_mode_changed.connect(func(enabled: bool):
			if check_dev_mode:
				check_dev_mode.set_pressed_no_signal(enabled)
		)
	if logout_btn:
		logout_btn.pressed.connect(_on_logout_pressed)
	reset_progress_btn.pressed.connect(func(): reset_confirm_modal.visible = true)
	cancel_reset_btn.pressed.connect(func(): reset_confirm_modal.visible = false)
	confirm_reset_btn.pressed.connect(_on_confirm_reset)

	load_settings_into_ui()
	_switch_tab(0)

func open_settings() -> void:
	load_settings_into_ui()
	visible = true
	var card = $Center/SettingsCard
	if card:
		card.scale = Vector2(0.92, 0.92)
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "scale", Vector2.ONE, 0.22)

func close_settings() -> void:
	visible = false
	if reset_confirm_modal:
		reset_confirm_modal.visible = false
	settings_closed.emit()

func load_settings_into_ui() -> void:
	# Audio Values
	var m_vol: float = float(SaveManager.get_setting("master_volume", 1.0))
	var bgm_vol: float = float(SaveManager.get_setting("music_volume", 0.8))
	var sfx_vol: float = float(SaveManager.get_setting("sfx_volume", 1.0))

	master_slider.value = m_vol * 100.0
	master_val_label.text = "%d%%" % int(master_slider.value)

	music_slider.value = bgm_vol * 100.0
	music_val_label.text = "%d%%" % int(music_slider.value)

	sfx_slider.value = sfx_vol * 100.0
	sfx_val_label.text = "%d%%" % int(sfx_slider.value)

	# Visual Values
	var font_size: String = str(SaveManager.get_setting("code_font_size", "medium"))
	_update_font_buttons_style(font_size)

	check_shake.button_pressed = bool(SaveManager.get_setting("screen_shake", true))
	check_flash.button_pressed = bool(SaveManager.get_setting("screen_flash", true))
	check_fullscreen.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

	# Controls & Account Values
	check_joystick.button_pressed = bool(SaveManager.get_setting("show_joystick", true))
	if check_dev_mode:
		check_dev_mode.set_pressed_no_signal(SaveManager.is_dev_mode())

	var is_guest: bool = SaveManager.is_guest()
	var p_name: String = SaveManager.user_profile.get("full_name", "Adventurer Alex")
	if is_guest:
		account_status_label.text = "⚔️ Guest Adventurer: %s (Local Storage)" % p_name
		account_status_label.modulate = Color("#FBBF24")
		if logout_btn:
			logout_btn.text = "🔑 Log In / Switch Account"
	else:
		account_status_label.text = "☁️ Cloud Synced Account: %s" % p_name
		account_status_label.modulate = Color("#34D399")
		if logout_btn:
			logout_btn.text = "🚪 Log Out"

func _switch_tab(tab_idx: int) -> void:
	active_tab = tab_idx
	panel_audio.visible = (tab_idx == 0)
	panel_visuals.visible = (tab_idx == 1)
	panel_controls.visible = (tab_idx == 2)

	_style_tab_button(tab_audio_btn, tab_idx == 0)
	_style_tab_button(tab_visuals_btn, tab_idx == 1)
	_style_tab_button(tab_controls_btn, tab_idx == 2)

func _style_tab_button(btn: Button, is_active: bool) -> void:
	var box = StyleBoxFlat.new()
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_left = 4
	box.corner_radius_bottom_right = 4
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	box.border_width_bottom = 3

	if is_active:
		box.bg_color = Color(0.18, 0.12, 0.28, 1.0)
		box.border_color = Color(0.96, 0.72, 0.15, 1.0)
		btn.add_theme_color_override("font_color", Color(0.98, 0.85, 0.4, 1.0))
	else:
		box.bg_color = Color(0.09, 0.08, 0.14, 0.85)
		box.border_color = Color(0.24, 0.2, 0.35, 0.7)
		btn.add_theme_color_override("font_color", Color(0.7, 0.72, 0.8, 0.85))

	btn.add_theme_stylebox_override("normal", box)
	btn.add_theme_stylebox_override("hover", box)
	btn.add_theme_stylebox_override("pressed", box)

func _on_master_slider_changed(val: float) -> void:
	master_val_label.text = "%d%%" % int(val)
	var norm = val / 100.0
	SaveManager.set_setting("master_volume", norm)
	AudioManager.set_master_volume(norm)

func _on_music_slider_changed(val: float) -> void:
	music_val_label.text = "%d%%" % int(val)
	var norm = val / 100.0
	SaveManager.set_setting("music_volume", norm)
	AudioManager.set_music_volume(norm)

func _on_sfx_slider_changed(val: float) -> void:
	sfx_val_label.text = "%d%%" % int(val)
	var norm = val / 100.0
	SaveManager.set_setting("sfx_volume", norm)
	AudioManager.set_sfx_volume(norm)

func _on_test_sfx_pressed() -> void:
	AudioManager.play_sfx("res://assets/audio/sfx_chime.wav")

func _set_code_font_size(size_str: String) -> void:
	SaveManager.set_setting("code_font_size", size_str)
	_update_font_buttons_style(size_str)

func _update_font_buttons_style(size_str: String) -> void:
	_style_choice_btn(font_small_btn, size_str == "small")
	_style_choice_btn(font_med_btn, size_str == "medium")
	_style_choice_btn(font_large_btn, size_str == "large")

	var preview_size = 14
	if size_str == "small":
		preview_size = 12
	elif size_str == "large":
		preview_size = 18
	code_preview_label.add_theme_font_size_override("normal_font_size", preview_size)

func _style_choice_btn(btn: Button, selected: bool) -> void:
	var box = StyleBoxFlat.new()
	box.corner_radius_top_left = 6
	box.corner_radius_top_right = 6
	box.corner_radius_bottom_left = 6
	box.corner_radius_bottom_right = 6
	box.set_border_width_all(1)
	if selected:
		box.bg_color = Color(0.2, 0.16, 0.32, 1.0)
		box.border_color = Color(0.96, 0.72, 0.15, 1.0)
		btn.add_theme_color_override("font_color", Color(0.98, 0.85, 0.4, 1.0))
	else:
		box.bg_color = Color(0.1, 0.1, 0.16, 0.85)
		box.border_color = Color(0.28, 0.28, 0.4, 0.7)
		btn.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85, 1.0))
	btn.add_theme_stylebox_override("normal", box)
	btn.add_theme_stylebox_override("hover", box)
	btn.add_theme_stylebox_override("pressed", box)

func _on_shake_toggled(pressed: bool) -> void:
	SaveManager.set_setting("screen_shake", pressed)

func _on_flash_toggled(pressed: bool) -> void:
	SaveManager.set_setting("screen_flash", pressed)

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_joystick_toggled(pressed: bool) -> void:
	SaveManager.set_setting("show_joystick", pressed)
	# Also update current scene virtual joystick visibility if present
	var cur_scene = get_tree().current_scene
	if cur_scene and cur_scene.has_node("%VirtualJoystick"):
		cur_scene.get_node("%VirtualJoystick").visible = pressed

func _on_dev_mode_toggled(pressed: bool) -> void:
	SaveManager.set_dev_mode(pressed)

func _on_logout_pressed() -> void:
	close_settings()
	FirebaseManager.logout()
	SceneManager.change_scene(SceneManager.LOGIN)

func _on_confirm_reset() -> void:
	reset_confirm_modal.visible = false
	
	# Retain current settings & account name/identity
	var current_settings = SaveManager.user_profile.get("settings", {}).duplicate(true)
	var is_guest_user = SaveManager.is_guest()
	var current_name = SaveManager.user_profile.get("full_name", "Adventurer Alex" if is_guest_user else "Player")
	
	# Reset profile to a fresh Level 1 state (0 XP, Level 1, 5 Hint Tokens, W1 unlocked only)
	var fresh_profile = SaveManager.get_default_profile(is_guest_user)
	fresh_profile["full_name"] = current_name
	fresh_profile["settings"] = current_settings
	
	# Explicitly wipe all quest data, world states, and chests
	fresh_profile["xp"] = 0
	fresh_profile["player_level"] = 1
	fresh_profile["hint_tokens"] = 5
	fresh_profile["unlocked_level"] = 1
	fresh_profile["current_level"] = 1
	fresh_profile["level_stars"] = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
	fresh_profile["chests_opened"] = []
	fresh_profile["w1_shrines"] = []
	fresh_profile["w1_npcs"] = []
	fresh_profile["w2_shrines"] = []
	fresh_profile["w2_bridges"] = []
	fresh_profile["w2_npcs_helped"] = []
	fresh_profile["w3_shrines"] = []
	fresh_profile["w3_seals"] = []
	fresh_profile["w3_npcs_helped"] = []
	fresh_profile["w4_shrines"] = []
	fresh_profile["w4_gates"] = []
	fresh_profile["w4_inventory"] = []
	fresh_profile["w4_npcs_helped"] = []
	fresh_profile["w5_seals"] = []
	fresh_profile["w5_npcs_helped"] = []
	fresh_profile["worlds_visited"] = []
	
	SaveManager.user_profile = fresh_profile
	SaveManager.save_local_profile()
	
	if not is_guest_user and FirebaseManager.is_authenticated():
		FirebaseManager.write_player_profile(SaveManager.user_profile)
		
	close_settings()
	SceneManager.change_scene(SceneManager.MAIN_MENU)

