# res://scripts/ui/AuthUI.gd
extends Control

@export var is_signup_screen: bool = false

@onready var email_input: LineEdit = $CenterContainer/CardPanel/FormContainer/EmailInput
@onready var password_input: LineEdit = $CenterContainer/CardPanel/FormContainer/PasswordInput
@onready var full_name_input: LineEdit = get_node_or_null("CenterContainer/CardPanel/FormContainer/FullNameInput")
@onready var confirm_password_input: LineEdit = get_node_or_null("CenterContainer/CardPanel/FormContainer/ConfirmPasswordInput")
@onready var submit_button: Button = $CenterContainer/CardPanel/FormContainer/SubmitButton
@onready var guest_button: Button = get_node_or_null("CenterContainer/CardPanel/FormContainer/GuestButton")
@onready var switch_mode_button: Button = $CenterContainer/CardPanel/FormContainer/SwitchModeButton
@onready var status_label: Label = $CenterContainer/CardPanel/FormContainer/StatusLabel

# Color palette constants
const COLOR_ERROR: Color = Color("EF4444")   # Soft Red
const COLOR_SUCCESS: Color = Color("10B981") # Emerald Green
const COLOR_INFO: Color = Color("F59E0B")    # Gold / Amber

func _ready() -> void:
	FirebaseManager.auth_success.connect(_on_auth_success)
	FirebaseManager.auth_failed.connect(_on_auth_failed)
	status_label.text = ""
	if guest_button:
		guest_button.pressed.connect(_on_guest_button_pressed)

func _on_guest_button_pressed() -> void:
	if SaveManager.user_profile.is_empty() or not SaveManager.user_profile.has("full_name") or SaveManager.user_profile["full_name"] == "":
		SaveManager.user_profile["full_name"] = "Adventurer Alex"
	SaveManager.save_local_profile()
	SceneManager.change_scene(SceneManager.MAIN_MENU)

func _on_submit_button_pressed() -> void:
	var email: String = email_input.text.strip_edges()
	var password: String = password_input.text.strip_edges()
	
	if email.is_empty() or password.is_empty():
		_show_status("Please fill in all fields.", COLOR_ERROR)
		return
		
	if is_signup_screen:
		var full_name: String = full_name_input.text.strip_edges() if full_name_input else ""
		var confirm_pwd: String = confirm_password_input.text.strip_edges() if confirm_password_input else ""
		
		if full_name.is_empty():
			_show_status("Please enter your full name.", COLOR_ERROR)
			return
			
		if password != confirm_pwd:
			_show_status("Passwords do not match.", COLOR_ERROR)
			return
			
		_set_form_disabled(true)
		_show_status("Creating account...", COLOR_INFO)
		FirebaseManager.signup_user(email, password, full_name)
	else:
		_set_form_disabled(true)
		_show_status("Logging in...", COLOR_INFO)
		FirebaseManager.login_user(email, password)

func _on_auth_success(_user_data: Dictionary) -> void:
	_show_status("Success! Entering PyQuest...", COLOR_SUCCESS)
	await get_tree().create_timer(0.6).timeout
	SceneManager.change_scene(SceneManager.MAIN_MENU)

func _on_auth_failed(error_msg: String) -> void:
	_set_form_disabled(false)
	_show_status(error_msg, COLOR_ERROR)

func _on_switch_mode_button_pressed() -> void:
	if is_signup_screen:
		SceneManager.change_scene(SceneManager.LOGIN)
	else:
		SceneManager.change_scene(SceneManager.SIGN_UP)

func _show_status(text_msg: String, text_color: Color) -> void:
	status_label.text = text_msg
	status_label.add_theme_color_override("font_color", text_color)

func _set_form_disabled(disabled: bool) -> void:
	submit_button.disabled = disabled
	switch_mode_button.disabled = disabled
	email_input.editable = not disabled
	password_input.editable = not disabled
	if full_name_input:
		full_name_input.editable = not disabled
	if confirm_password_input:
		confirm_password_input.editable = not disabled
