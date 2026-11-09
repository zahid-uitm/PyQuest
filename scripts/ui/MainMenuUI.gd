# res://scripts/ui/MainMenuUI.gd
extends Control

@onready var user_name_label: Label = $HangingSignboard/WoodPlank/PlankVBox/UserNameLabel
@onready var level_label: Label = $HangingSignboard/WoodPlank/PlankVBox/LevelLabel
@onready var xp_progress_bar: ProgressBar = $HangingSignboard/WoodPlank/PlankVBox/XPContainer/XPProgressBar
@onready var hanging_signboard: Control = get_node_or_null("HangingSignboard")
@onready var title_logo: TextureRect = get_node_or_null("TitleLogo")
@onready var settings_modal: Control = get_node_or_null("SettingsModal")
@onready var badges_modal: Control = get_node_or_null("BadgesModal")
@onready var leaderboard_modal: Control = get_node_or_null("LeaderboardModal")
@onready var cutscenes_modal: Control = get_node_or_null("CutscenesModal")
@onready var exit_btn: Button = get_node_or_null("StoneMonolith/MonolithVBox/ExitButton")
@onready var stone_drawer: Control = get_node_or_null("StoneMonolith/StoneDrawer")
@onready var drawer_handle_btn: TextureButton = get_node_or_null("StoneMonolith/StoneDrawer/DrawerHandleBtn")
@onready var badge_icon_btn: TextureButton = get_node_or_null("StoneMonolith/StoneDrawer/BadgeIconBtn")
@onready var leaderboard_icon_btn: TextureButton = get_node_or_null("StoneMonolith/StoneDrawer/LeaderboardIconBtn")
@onready var settings_icon_btn: TextureButton = get_node_or_null("StoneMonolith/StoneDrawer/SettingsIconBtn")

const DRAWER_EXPANDED_X: float = 496.0
const DRAWER_RETRACTED_X: float = 240.0

var _drawer_expanded: bool = false
var _drawer_tween: Tween = null
var _is_dragging_drawer: bool = false
var _drag_did_move: bool = false
var _drag_start_mouse_x: float = 0.0
var _drag_start_drawer_x: float = 0.0

func _ready() -> void:
	AudioManager.play_bgm_by_path("res://assets/audio/mainmenu_music.mp3", 0.01)
	update_dashboard()
	_start_hanging_sign_sway()
	_start_title_bob()
	_setup_stone_drawer()
	if settings_modal and settings_modal.has_signal("settings_closed"):
		settings_modal.settings_closed.connect(update_dashboard)
	
	# Check for "First Steps" achievement upon arriving at the Main Menu
	call_deferred("_check_first_timer_badge")

func _check_first_timer_badge() -> void:
	# Give the scene and UI half a second to settle in before popping the toast
	await get_tree().create_timer(0.6).timeout
	if Engine.has_singleton("BadgeManager") or get_node_or_null("/root/BadgeManager"):
		var bm = get_node("/root/BadgeManager")
		if bm.has_method("unlock_badge"):
			bm.unlock_badge("first_steps")
			update_dashboard()

func _start_title_bob() -> void:
	if not title_logo:
		return
	var base_y: float = title_logo.position.y
	var bob_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob_tween.tween_property(title_logo, "position:y", base_y - 6.0, 2.2)
	bob_tween.tween_property(title_logo, "position:y", base_y + 6.0, 2.2)

func _start_hanging_sign_sway() -> void:
	if not hanging_signboard:
		return
	
	# Set pivot at top center so the sign physically swings like a pendulum from its hanging ropes
	hanging_signboard.pivot_offset = Vector2(hanging_signboard.size.x * 0.5, 0.0)
	
	# Prominent, natural pendulum swing like PvZ hanging wooden sign
	var sway_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway_tween.tween_property(hanging_signboard, "rotation", 0.065, 2.0)
	sway_tween.tween_property(hanging_signboard, "rotation", -0.065, 2.0)

func update_dashboard() -> void:
	var profile: Dictionary = SaveManager.user_profile
	
	var raw_name: String = profile.get("full_name", "Player")
	var current_level: int = int(profile.get("player_level", 1))
	
	if SaveManager.is_guest():
		user_name_label.text = "⚔️ %s (Guest)" % raw_name
		level_label.text = "Level %d Adventurer • Local Device Storage" % current_level
	else:
		user_name_label.text = "Welcome back, %s!" % raw_name
		level_label.text = "Level %d Adventurer • Cloud Sync Active" % current_level
	
	if exit_btn:
		exit_btn.text = "EXIT GAME"
	
	var current_xp: int = int(profile.get("xp", 0))
	var xp_in_level: int = current_xp % 500
	
	xp_progress_bar.max_value = 500
	
	# Smoothly animate XP progress bar load
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(xp_progress_bar, "value", xp_in_level, 0.8)

func _on_continue_quest_button_pressed() -> void:
	var unlocked: int = int(SaveManager.user_profile.get("unlocked_level", 1))
	SaveManager.user_profile["current_level"] = unlocked
	var intro_watched: bool = bool(SaveManager.user_profile.get("intro_watched", false))
	if unlocked == 1 and not intro_watched:
		SceneManager.change_scene_with_loading(SceneManager.CINEMATIC_INTRO)
		return
	if unlocked >= 6:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_6)
	elif unlocked == 5:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_5)
	elif unlocked == 4:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_4)
	elif unlocked == 3:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_3)
	elif unlocked == 2:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_2)
	else:
		SceneManager.change_scene_with_loading(SceneManager.WORLD_1)

func _on_intro_cinematic_button_pressed() -> void:
	if cutscenes_modal and cutscenes_modal.has_method("open_modal"):
		cutscenes_modal.open_modal()
	else:
		SceneManager.change_scene(SceneManager.CINEMATIC_INTRO)

func _on_level_select_button_pressed() -> void:
	SceneManager.change_scene(SceneManager.LEVEL_SELECT)

func _on_badges_button_pressed() -> void:
	if badges_modal and badges_modal.has_method("open_modal"):
		badges_modal.open_modal()

func _on_leaderboard_button_pressed() -> void:
	if leaderboard_modal and leaderboard_modal.has_method("open_modal"):
		leaderboard_modal.open_modal()

func _on_settings_button_pressed() -> void:
	if settings_modal and settings_modal.has_method("open_settings"):
		settings_modal.open_settings()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _setup_stone_drawer() -> void:
	if not stone_drawer:
		return
	var icons: Array[TextureButton] = [badge_icon_btn, leaderboard_icon_btn, settings_icon_btn]
	for btn in icons:
		if btn:
			btn.pivot_offset = btn.size * 0.5
			btn.mouse_entered.connect(_on_medallion_hover.bind(btn, true))
			btn.mouse_exited.connect(_on_medallion_hover.bind(btn, false))
	if drawer_handle_btn:
		drawer_handle_btn.pivot_offset = drawer_handle_btn.size * 0.5
		drawer_handle_btn.mouse_entered.connect(_on_medallion_hover.bind(drawer_handle_btn, true))
		drawer_handle_btn.mouse_exited.connect(_on_medallion_hover.bind(drawer_handle_btn, false))
	_set_drawer_expanded(false, false)

func _on_medallion_hover(btn: Control, hovered: bool) -> void:
	if not is_instance_valid(btn):
		return
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if hovered:
		tw.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.16)
		tw.parallel().tween_property(btn, "modulate", Color(1.15, 1.12, 1.04, 1.0), 0.16)
	else:
		tw.tween_property(btn, "scale", Vector2.ONE, 0.18)
		tw.parallel().tween_property(btn, "modulate", Color.WHITE, 0.18)

func _on_drawer_handle_pressed() -> void:
	if _drag_did_move:
		_drag_did_move = false
		return
	_set_drawer_expanded(not _drawer_expanded, true)

func _on_drawer_handle_gui_input(event: InputEvent) -> void:
	if not stone_drawer:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_dragging_drawer = true
			_drag_did_move = false
			_drag_start_mouse_x = event.global_position.x
			_drag_start_drawer_x = stone_drawer.position.x
			if _drawer_tween and _drawer_tween.is_valid():
				_drawer_tween.kill()
		else:
			if _is_dragging_drawer:
				_is_dragging_drawer = false
				if _drag_did_move:
					var midpoint: float = (DRAWER_EXPANDED_X + DRAWER_RETRACTED_X) * 0.5
					var target_expand: bool = stone_drawer.position.x >= midpoint
					_set_drawer_expanded(target_expand, true)
	elif event is InputEventMouseMotion and _is_dragging_drawer:
		var delta_x: float = event.global_position.x - _drag_start_mouse_x
		if absf(delta_x) > 5.0:
			_drag_did_move = true
		var new_x: float = clampf(_drag_start_drawer_x + delta_x, DRAWER_RETRACTED_X, DRAWER_EXPANDED_X)
		stone_drawer.position.x = new_x
		var ratio: float = inverse_lerp(DRAWER_RETRACTED_X, DRAWER_EXPANDED_X, new_x)
		_update_drawer_icons_visibility(ratio)

func _set_drawer_expanded(expanded: bool, animate: bool = true) -> void:
	_drawer_expanded = expanded
	if not stone_drawer:
		return
	var target_x: float = DRAWER_EXPANDED_X if expanded else DRAWER_RETRACTED_X
	if drawer_handle_btn:
		drawer_handle_btn.flip_h = expanded
	
	var icons: Array[TextureButton] = [badge_icon_btn, leaderboard_icon_btn, settings_icon_btn]
	for btn in icons:
		if btn:
			btn.disabled = not expanded
			btn.mouse_filter = Control.MOUSE_FILTER_STOP if expanded else Control.MOUSE_FILTER_IGNORE
	
	if _drawer_tween and _drawer_tween.is_valid():
		_drawer_tween.kill()
	
	if animate:
		_drawer_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_drawer_tween.tween_property(stone_drawer, "position:x", target_x, 0.38)
		for btn in icons:
			if btn:
				_drawer_tween.parallel().tween_property(btn, "modulate:a", 1.0 if expanded else 0.0, 0.25)
	else:
		stone_drawer.position.x = target_x
		_update_drawer_icons_visibility(1.0 if expanded else 0.0)

func _update_drawer_icons_visibility(ratio: float) -> void:
	var alpha: float = clampf((ratio - 0.25) / 0.75, 0.0, 1.0)
	var icons: Array[TextureButton] = [badge_icon_btn, leaderboard_icon_btn, settings_icon_btn]
	for btn in icons:
		if btn:
			btn.modulate.a = alpha
