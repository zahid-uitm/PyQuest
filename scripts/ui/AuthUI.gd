# res://scripts/ui/AuthUI.gd
extends Control

@export var is_signup_screen: bool = false

@onready var email_input: LineEdit = $FormContainer/EmailInput
@onready var password_input: LineEdit = $FormContainer/PasswordInput
@onready var full_name_input: LineEdit = $FormContainer/FullNameInput # Only in SignUp scene[cite: 56]
@onready var confirm_password_input: LineEdit = $FormContainer/ConfirmPasswordInput # Only in SignUp scene[cite: 56]
@onready var status_label: Label = $FormContainer/StatusLabel

func _ready() -> void:
	FirebaseManager.auth_success.connect(_on_auth_success)
	FirebaseManager.auth_failed.connect(_on_auth_failed)

func _on_submit_button_pressed() -> void:
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if email.is_empty() or password.is_empty():
		status_label.text = "Please fill in all fields."
		return
		
	if is_signup_screen:
		var confirm_pwd = confirm_password_input.text.strip_edges()
		if password != confirm_pwd:
			status_label.text = "Passwords do not match."
			return
		status_label.text = "Creating account..."
		FirebaseManager.signup_user(email, password, full_name_input.text)
	else:
		status_label.text = "Logging in..."
		FirebaseManager.login_user(email, password)

func _on_auth_success(_user_data: Dictionary) -> void:
	SceneManager.change_scene(SceneManager.MAIN_MENU)

func _on_auth_failed(error_msg: String) -> void:
	status_label.text = "Error: " + error_msg

func _on_switch_auth_mode_pressed() -> void:
	if is_signup_screen:
		SceneManager.change_scene(SceneManager.LOGIN)
	else:
		SceneManager.change_scene(SceneManager.SIGN_UP)


func _on_switch_mode_button_pressed() -> void:
	if is_signup_screen:
		SceneManager.change_scene(SceneManager.LOGIN)
	else:
		SceneManager.change_scene(SceneManager.SIGN_UP)
