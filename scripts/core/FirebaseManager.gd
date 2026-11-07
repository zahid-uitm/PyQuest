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
var http_db_read: HTTPRequest
var http_db_write: HTTPRequest

func _ready() -> void:
	http_auth = HTTPRequest.new()
	http_db_read = HTTPRequest.new()
	http_db_write = HTTPRequest.new()
	add_child(http_auth)
	add_child(http_db_read)
	add_child(http_db_write)
	
	http_auth.request_completed.connect(_on_auth_request_completed)
	http_db_read.request_completed.connect(_on_db_read_completed)
	http_db_write.request_completed.connect(_on_db_write_completed)

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
	var err = http_db_write.request(url, headers, HTTPClient.METHOD_PUT, JSON.stringify(profile_data))
	print("⚡ [FirebaseManager] Queued profile write to RTDB (error_code: %d)" % err)

func fetch_player_profile() -> void:
	if not is_authenticated():
		push_error("Cannot read DB without authentication.")
		return
		
	var url = "%s/users/%s.json?auth=%s" % [DB_URL, current_user_id, id_token]
	var err = http_db_read.request(url, [], HTTPClient.METHOD_GET)
	print("⚡ [FirebaseManager] Reading user profile from RTDB (error_code: %d)" % err)

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

func _on_db_read_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var response_text = body.get_string_from_utf8()
	print("⚡ [FirebaseManager] DB Read Response Code: %d" % response_code)
	
	if response_code == 200:
		var profile = JSON.parse_string(response_text)
		
		if typeof(profile) == TYPE_DICTIONARY:
			profile["is_guest"] = false
			
			# Auto-max profile for testing when zahid hakimi logs in
			if current_user_id == "bcLI1yq389g4JToSxdC9rhQRFL83" or str(profile.get("full_name", "")).to_lower().contains("zahid"):
				print("⚡ [FirebaseManager] Auto-maxing test account for Zahid Hakimi...")
				profile["full_name"] = "zahid hakimi"
				profile["unlocked_level"] = 4
				profile["player_level"] = 10
				profile["xp"] = 5000
				profile["hint_tokens"] = 99
				profile["current_level"] = 4
				profile["level_stars"] = {
					"1": 3,
					"2": 3,
					"3": 3,
					"4": 3,
					"5": 3
				}
				profile["w1_shrines"] = ["shrine_numbers", "shrine_strings", "shrine_booleans"]
				profile["w1_npcs"] = ["npc_farmer_bob", "npc_blacksmith_dan", "npc_alchemist_elena"]
				profile["w2_shrines"] = ["shrine_if_else", "shrine_for_loops", "shrine_while_loops"]
				profile["w2_bridges"] = ["bridge_chasm_left", "bridge_chasm_right"]
				profile["w2_npcs_helped"] = ["npc_keeper_venn", "npc_weaver_sera", "npc_sentinel_kael"]
				profile["w3_shrines"] = ["shrine_def", "shrine_params", "shrine_return"]
				profile["w3_seals"] = ["seal_west", "seal_east"]
				profile["w3_npcs_helped"] = ["npc_archivist_def", "npc_artificer_param", "npc_oracle_ret"]
				profile["w4_shrines"] = ["shrine_indexing", "shrine_mutation", "shrine_sequences"]
				profile["w4_gates"] = ["gate_west", "gate_east"]
				profile["w4_inventory"] = ["skull_key", "jade_urn", "soul_gem"]
				profile["w4_npcs_helped"] = ["npc_curator_idx", "npc_warden_mut", "npc_seers_seq"]
				
				SaveManager.user_profile = profile
				SaveManager.save_local_profile()
				write_player_profile(profile)
				auth_success.emit({"user_id": current_user_id})
				return

			SaveManager.user_profile = profile
			SaveManager.save_local_profile()
			auth_success.emit({"user_id": current_user_id})
		elif profile == null:
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

func _on_db_write_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("⚡ [FirebaseManager] DB Write Response Code: %d" % response_code)
	var response_text = body.get_string_from_utf8()
	if response_code == 200:
		print("⚡ [FirebaseManager] Firebase RTDB synced successfully!")
	else:
		print("⚠️ [FirebaseManager] Firebase RTDB sync failed: ", response_text)
	db_write_complete.emit(response_code == 200)

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
