# res://scripts/core/FirebaseManager.gd
extends Node

signal auth_success(user_data: Dictionary)
signal auth_failed(error_msg: String)
signal db_write_complete(success: bool)

const API_KEY: String = "AIzaSyAefjAz8cKAfSJPRVhf-IKctdl1csVit1M"
const DB_URL: String = "https://pyquest-fyp-default-rtdb.firebaseio.com"

const AUTH_SIGNUP_URL = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key="
const AUTH_LOGIN_URL = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key="

var current_user_id: String = ""
var id_token: String = ""

var http_auth: HTTPRequest
var http_db: HTTPRequest

func _ready() -> void:
	http_auth = HTTPRequest.new()
	http_db = HTTPRequest.new()
	add_child(http_auth)
	add_child(http_db)
	
	http_auth.request_completed.connect(_on_auth_request_completed)
	http_db.request_completed.connect(_on_db_request_completed)

func is_authenticated() -> bool:
	return not id_token.is_empty()

func signup_user(email: String, password: String, full_name: String) -> void:
	var payload = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	var headers = ["Content-Type: application/json"]
	http_auth.set_meta("action", "signup")
	http_auth.set_meta("full_name", full_name)
	http_auth.request(AUTH_SIGNUP_URL + API_KEY, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))

func login_user(email: String, password: String) -> void:
	var payload = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	var headers = ["Content-Type: application/json"]
	http_auth.set_meta("action", "login")
	http_auth.request(AUTH_LOGIN_URL + API_KEY, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))

func logout() -> void:
	current_user_id = ""
	id_token = ""

func write_player_profile(profile_data: Dictionary) -> void:
	if not is_authenticated():
		push_error("Cannot write to DB without authentication.")
		return
	
	var url = "%s/users/%s.json?auth=%s" % [DB_URL, current_user_id, id_token]
	var headers = ["Content-Type: application/json"]
	http_db.request(url, headers, HTTPClient.METHOD_PUT, JSON.stringify(profile_data))

func _on_auth_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	if response_code == 200:
		current_user_id = response["localId"]
		id_token = response["idToken"]
		
		var action = http_auth.get_meta("action")
		if action == "signup":
			var full_name = http_auth.get_meta("full_name")
			var initial_profile = {
				"full_name": full_name,
				"player_level": 1,
				"xp": 0,
				"unlocked_level": 1,
				"hint_tokens": 5
			}
			SaveManager.user_profile = initial_profile
			write_player_profile(initial_profile)
		
		auth_success.emit(response)
	else:
		var err_message = response.get("error", {}).get("message", "Authentication Failed")
		auth_failed.emit(err_message)

func _on_db_request_completed(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	db_write_complete.emit(response_code == 200)
