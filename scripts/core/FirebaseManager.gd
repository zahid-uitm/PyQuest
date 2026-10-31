# res://scripts/core/FirebaseManager.gd
extends Node

signal auth_success(user_data: Dictionary)
signal auth_failed(error_msg: String)
signal db_write_complete(success: bool)

const API_KEY: String = "AIzaSyAefjAz8cKAfSJPRVhf-IKctdl1csVit1M"
const DB_URL: String = "https://pyquest-8ad56-default-rtdb.asia-southeast1.firebasedatabase.app"

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
	SaveManager.clear_profile()

func write_player_profile(profile_data: Dictionary) -> void:
	if not is_authenticated():
		push_error("Cannot write to DB without authentication.")
		return
	
	var url = "%s/users/%s.json?auth=%s" % [DB_URL, current_user_id, id_token]
	var headers = ["Content-Type: application/json"]
	http_db.set_meta("action", "write_profile")
	http_db.request(url, headers, HTTPClient.METHOD_PUT, JSON.stringify(profile_data))

func fetch_player_profile() -> void:
	if not is_authenticated():
		push_error("Cannot read DB without authentication.")
		return
		
	var url = "%s/users/%s.json?auth=%s" % [DB_URL, current_user_id, id_token]
	http_db.set_meta("action", "read_profile")
	http_db.request(url, [], HTTPClient.METHOD_GET)

func _on_auth_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var response_text = body.get_string_from_utf8()
	var response = JSON.parse_string(response_text)
	
	if typeof(response) != TYPE_DICTIONARY:
		auth_failed.emit("Server response invalid.")
		return

	if response_code == 200:
		current_user_id = response.get("localId", "")
		id_token = response.get("idToken", "")
		
		var action = http_auth.get_meta("action") if http_auth.has_meta("action") else ""
		
		if action == "signup":
			var full_name = http_auth.get_meta("full_name") if http_auth.has_meta("full_name") else "Player"
			var initial_profile = {
				"full_name": full_name,
				"is_guest": false,
				"player_level": 1,
				"xp": 0,
				"unlocked_level": 1,
				"hint_tokens": 5,
				"current_level": 1,
				"level_stars": {
					"1": 0,
					"2": 0,
					"3": 0,
					"4": 0,
					"5": 0
				}
			}
			SaveManager.user_profile = initial_profile
			SaveManager.save_local_profile()
			write_player_profile(initial_profile)
			auth_success.emit(response)
		elif action == "login":
			# Fetch profile data from RTDB after successful authentication
			fetch_player_profile()
			
		# Clean up metadata
		if http_auth.has_meta("action"): http_auth.remove_meta("action")
		if http_auth.has_meta("full_name"): http_auth.remove_meta("full_name")
	else:
		var raw_error = response.get("error", {}).get("message", "AUTH_FAILED")
		auth_failed.emit(_clean_error_message(raw_error))

func _on_db_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var db_action = http_db.get_meta("action") if http_db.has_meta("action") else ""
	var response_text = body.get_string_from_utf8()
	
	if db_action == "read_profile":
		print("DB Read Response Code: ", response_code)
		print("DB Read Body: ", response_text)
		
		if response_code == 200:
			var profile = JSON.parse_string(response_text)
			
			if typeof(profile) == TYPE_DICTIONARY:
				profile["is_guest"] = false
				SaveManager.user_profile = profile
				SaveManager.save_local_profile()
				auth_success.emit({"user_id": current_user_id})
			elif profile == null:
				# Profile doesn't exist in DB yet (e.g. account created during earlier failed test)
				# Auto-generate initial profile
				var default_profile = {
					"full_name": "Player",
					"is_guest": false,
					"player_level": 1,
					"xp": 0,
					"unlocked_level": 1,
					"hint_tokens": 5,
					"current_level": 1,
					"level_stars": {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
				}
				SaveManager.user_profile = default_profile
				SaveManager.save_local_profile()
				write_player_profile(default_profile)
				auth_success.emit({"user_id": current_user_id})
			else:
				auth_failed.emit("Failed to load user profile from database.")
		else:
			auth_failed.emit("Failed to load user profile (HTTP %d)." % response_code)
	else:
		db_write_complete.emit(response_code == 200)
		
	if http_db.has_meta("action"): http_db.remove_meta("action")

func _clean_error_message(raw_msg: String) -> String:
	if "EMAIL_EXISTS" in raw_msg:
		return "An account with this email already exists."
	elif "INVALID_EMAIL" in raw_msg:
		return "Please enter a valid email address."
	elif "WEAK_PASSWORD" in raw_msg:
		return "Password must be at least 6 characters."
	elif "INVALID_LOGIN_CREDENTIALS" in raw_msg or "INVALID_PASSWORD" in raw_msg or "EMAIL_NOT_FOUND" in raw_msg:
		return "Invalid email or password."
	elif "USER_DISABLED" in raw_msg:
		return "This account has been disabled."
	return "Authentication Error: " + raw_msg
