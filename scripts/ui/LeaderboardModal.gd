# res://scripts/ui/LeaderboardModal.gd
extends ColorRect

signal modal_closed

@onready var modal_card: PanelContainer = %ModalCard
@onready var close_btn: Button = %CloseBtn

# Tabs
@onready var tab_xp_btn: Button = %TabXPBtn
@onready var tab_stars_btn: Button = %TabStarsBtn
@onready var tab_badges_btn: Button = %TabBadgesBtn

# Content containers
@onready var guest_box: VBoxContainer = %GuestBox
@onready var content_box: VBoxContainer = %ContentBox
@onready var guest_login_btn: Button = %GuestLoginBtn
@onready var guest_cancel_btn: Button = %GuestCancelBtn

@onready var loading_box: VBoxContainer = %LoadingBox
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var rankings_vbox: VBoxContainer = %RankingsVBox
@onready var your_standing_card: PanelContainer = %YourStandingCard
@onready var your_standing_label: Label = %YourStandingLabel
@onready var header_summary_label: Label = %HeaderSummaryLabel

var current_tab: String = "xp" # "xp", "stars", "badges"
var raw_users_data: Dictionary = {}
var is_loading: bool = false

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(close_modal)

	if tab_xp_btn:
		tab_xp_btn.pressed.connect(func(): _switch_tab("xp"))
	if tab_stars_btn:
		tab_stars_btn.pressed.connect(func(): _switch_tab("stars"))
	if tab_badges_btn:
		tab_badges_btn.pressed.connect(func(): _switch_tab("badges"))

	if guest_login_btn:
		guest_login_btn.pressed.connect(_on_guest_login_pressed)
	if guest_cancel_btn:
		guest_cancel_btn.pressed.connect(close_modal)

	if not FirebaseManager.leaderboard_loaded.is_connected(_on_leaderboard_loaded):
		FirebaseManager.leaderboard_loaded.connect(_on_leaderboard_loaded)
	if not FirebaseManager.leaderboard_failed.is_connected(_on_leaderboard_failed):
		FirebaseManager.leaderboard_failed.connect(_on_leaderboard_failed)

func open_modal() -> void:
	visible = true
	current_tab = "xp"
	_update_tab_button_styles()

	if modal_card:
		modal_card.scale = Vector2(0.9, 0.9)
		modal_card.pivot_offset = modal_card.size * 0.5
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(modal_card, "scale", Vector2.ONE, 0.24)

	var is_guest_mode = SaveManager.is_guest() or not FirebaseManager.is_authenticated()
	if is_guest_mode:
		guest_box.visible = true
		content_box.visible = false
		if header_summary_label:
			header_summary_label.text = "Account Sign-in Required"
	else:
		guest_box.visible = false
		content_box.visible = true
		loading_box.visible = true
		scroll_container.visible = false
		your_standing_card.visible = false
		if header_summary_label:
			header_summary_label.text = "Synchronizing cloud rankings..."

		is_loading = true
		FirebaseManager.fetch_leaderboard()

func close_modal() -> void:
	visible = false
	modal_closed.emit()

func _switch_tab(tab_name: String) -> void:
	current_tab = tab_name
	_update_tab_button_styles()
	_render_rankings()

func _update_tab_button_styles() -> void:
	var tabs = [
		{"btn": tab_xp_btn, "key": "xp"},
		{"btn": tab_stars_btn, "key": "stars"},
		{"btn": tab_badges_btn, "key": "badges"}
	]
	for t in tabs:
		if not t["btn"]:
			continue
		var is_active = (t["key"] == current_tab)
		var st = StyleBoxFlat.new()
		st.corner_radius_top_left = 8
		st.corner_radius_top_right = 8
		st.corner_radius_bottom_right = 8
		st.corner_radius_bottom_left = 8
		st.content_margin_left = 14
		st.content_margin_right = 14
		st.content_margin_top = 8
		st.content_margin_bottom = 8

		if is_active:
			st.bg_color = Color(0.96, 0.72, 0.15, 0.92)
			st.border_color = Color(1.0, 0.9, 0.5, 1.0)
			st.set_border_width_all(2)
			t["btn"].add_theme_color_override("font_color", Color(0.08, 0.05, 0.01, 1.0))
		else:
			st.bg_color = Color(0.12, 0.15, 0.22, 0.8)
			st.border_color = Color(0.3, 0.38, 0.5, 0.6)
			st.set_border_width_all(1)
			t["btn"].add_theme_color_override("font_color", Color(0.8, 0.85, 0.95, 1.0))

		t["btn"].add_theme_stylebox_override("normal", st)
		t["btn"].add_theme_stylebox_override("hover", st)
		t["btn"].add_theme_stylebox_override("pressed", st)

func _on_leaderboard_loaded(users_data: Dictionary) -> void:
	is_loading = false
	raw_users_data = users_data
	if loading_box:
		loading_box.visible = false
	if scroll_container:
		scroll_container.visible = true
	_render_rankings()

func _on_leaderboard_failed(_error_msg: String) -> void:
	is_loading = false
	if loading_box:
		loading_box.visible = false
	if scroll_container:
		scroll_container.visible = true
	_render_rankings()

func _render_rankings() -> void:
	for c in rankings_vbox.get_children():
		c.queue_free()

	var players_list = _build_players_list()

	# Sort players according to active tab
	match current_tab:
		"xp":
			players_list.sort_custom(func(a, b):
				if a["xp"] != b["xp"]:
					return a["xp"] > b["xp"]
				return a["level"] > b["level"]
			)
		"stars":
			players_list.sort_custom(func(a, b):
				if a["stars"] != b["stars"]:
					return a["stars"] > b["stars"]
				return a["xp"] > b["xp"]
			)
		"badges":
			players_list.sort_custom(func(a, b):
				if a["badges"] != b["badges"]:
					return a["badges"] > b["badges"]
				return a["xp"] > b["xp"]
			)

	if header_summary_label:
		header_summary_label.text = "🏆 %d Adventurers Ranked • Live Cloud Hall of Fame" % players_list.size()

	# Find current player's standing
	var player_rank = -1
	var current_player_entry: Dictionary = {}
	for idx in range(players_list.size()):
		var p = players_list[idx]
		if p["is_current"]:
			player_rank = idx + 1
			current_player_entry = p
			break

	# Render pinned Your Standing card
	if player_rank > 0 and not current_player_entry.is_empty():
		your_standing_card.visible = true
		var stat_desc = _get_stat_string(current_player_entry)
		your_standing_label.text = "📍 Your Standing: Rank #%d  •  %s  •  Level %d  •  %s" % [
			player_rank,
			current_player_entry["name"],
			current_player_entry["level"],
			stat_desc
		]
	else:
		your_standing_card.visible = false

	# Build ranking row cards
	if players_list.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No registered players found in cloud database."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 14)
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.82))
		rankings_vbox.add_child(empty_lbl)
	else:
		for idx in range(players_list.size()):
			var p = players_list[idx]
			var rank = idx + 1
			var row_card = _build_ranking_row(rank, p)
			rankings_vbox.add_child(row_card)

func _build_players_list() -> Array:
	var list: Array = []
	var cur_uid = FirebaseManager.current_user_id
	var local_prof = SaveManager.user_profile
	var cur_player_added = false

	for u_id in raw_users_data.keys():
		var u_dict = raw_users_data[u_id]
		if typeof(u_dict) != TYPE_DICTIONARY:
			continue

		var is_cur = (u_id == cur_uid)
		var p_name = str(u_dict.get("full_name", "Adventurer"))
		var p_level = int(u_dict.get("player_level", 1))
		var p_xp = int(u_dict.get("xp", 0))

		# Compute stars
		var raw_stars = u_dict.get("level_stars", {})
		var total_stars = 0
		if typeof(raw_stars) == TYPE_DICTIONARY:
			for s in raw_stars.values():
				total_stars += int(s)
		elif typeof(raw_stars) == TYPE_ARRAY:
			for s in raw_stars:
				if s != null:
					total_stars += int(s)

		# Compute badges
		var raw_badges = u_dict.get("badges", [])
		var total_badges = 0
		if typeof(raw_badges) == TYPE_ARRAY or typeof(raw_badges) == TYPE_DICTIONARY:
			total_badges = raw_badges.size()

		# If this is the current active player, use local profile to reflect latest un-synced gains
		if is_cur:
			cur_player_added = true
			p_name = str(local_prof.get("full_name", p_name))
			p_level = int(local_prof.get("player_level", p_level))
			p_xp = int(local_prof.get("xp", p_xp))

		list.append({
			"id": u_id,
			"name": p_name,
			"level": p_level,
			"xp": p_xp,
			"stars": total_stars,
			"badges": total_badges,
			"is_current": is_cur
		})

	# If current logged in player wasn't in raw_users_data, add them
	if not cur_player_added and FirebaseManager.is_authenticated():
		var local_stars = 0
		var ls = local_prof.get("level_stars", {})
		if typeof(ls) == TYPE_DICTIONARY:
			for s in ls.values():
				local_stars += int(s)
		var lb = local_prof.get("badges", [])
		var local_badges = lb.size() if typeof(lb) == TYPE_ARRAY else 0

		list.append({
			"id": cur_uid,
			"name": str(local_prof.get("full_name", "Player")),
			"level": int(local_prof.get("player_level", 1)),
			"xp": int(local_prof.get("xp", 0)),
			"stars": local_stars,
			"badges": local_badges,
			"is_current": true
		})

	return list

func _get_stat_string(p: Dictionary) -> String:
	match current_tab:
		"xp":
			return "%s XP" % _format_number(p["xp"])
		"stars":
			return "%d / 12 ★" % p["stars"]
		"badges":
			return "%d / 17 🏅" % p["badges"]
	return ""

func _format_number(val: int) -> String:
	var s = str(val)
	var out = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = s[i] + out
		count += 1
	return out

func _build_ranking_row(rank: int, p: Dictionary) -> PanelContainer:
	var row = PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 60)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var is_current = bool(p["is_current"])

	var st = StyleBoxFlat.new()
	st.corner_radius_top_left = 10
	st.corner_radius_top_right = 10
	st.corner_radius_bottom_right = 10
	st.corner_radius_bottom_left = 10
	st.content_margin_left = 16
	st.content_margin_right = 18
	st.content_margin_top = 8
	st.content_margin_bottom = 8

	var rank_color: Color = Color(0.7, 0.75, 0.85)
	if rank == 1:
		rank_color = Color(1.0, 0.84, 0.2)   # Gold
		st.border_color = Color(1.0, 0.84, 0.2, 0.85)
		st.set_border_width_all(2)
		st.bg_color = Color(0.18, 0.14, 0.04, 0.92)
	elif rank == 2:
		rank_color = Color(0.82, 0.88, 0.95) # Silver
		st.border_color = Color(0.82, 0.88, 0.95, 0.7)
		st.set_border_width_all(2)
		st.bg_color = Color(0.12, 0.14, 0.18, 0.92)
	elif rank == 3:
		rank_color = Color(0.92, 0.58, 0.3)  # Bronze
		st.border_color = Color(0.92, 0.58, 0.3, 0.7)
		st.set_border_width_all(2)
		st.bg_color = Color(0.16, 0.10, 0.05, 0.92)
	elif is_current:
		st.border_color = Color(0.3, 0.85, 0.5, 0.8)
		st.set_border_width_all(2)
		st.bg_color = Color(0.06, 0.15, 0.10, 0.92)
	else:
		st.set_border_width_all(1)
		st.border_color = Color(0.25, 0.3, 0.4, 0.45)
		st.bg_color = Color(0.07, 0.09, 0.13, 0.88)

	row.add_theme_stylebox_override("panel", st)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	row.add_child(hbox)

	# 1. Rank Medallion
	var rank_lbl = Label.new()
	rank_lbl.custom_minimum_size = Vector2(50, 0)
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_lbl.add_theme_font_size_override("font_size", 18)
	rank_lbl.add_theme_color_override("font_color", rank_color)
	if rank == 1:
		rank_lbl.text = "🥇 #1"
	elif rank == 2:
		rank_lbl.text = "🥈 #2"
	elif rank == 3:
		rank_lbl.text = "🥉 #3"
	else:
		rank_lbl.text = "#%d" % rank
	hbox.add_child(rank_lbl)

	# 2. Avatar Icon
	var icon_lbl = Label.new()
	icon_lbl.add_theme_font_size_override("font_size", 22)
	icon_lbl.text = "🧙‍♂️" if rank <= 3 else "⚔️"
	hbox.add_child(icon_lbl)

	# 3. Name & Level VBox
	var name_vbox = VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(name_vbox)

	var name_lbl = Label.new()
	name_lbl.text = p["name"] + ("  (You)" if is_current else "")
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.65) if is_current else (Color.WHITE if rank <= 3 else Color(0.85, 0.9, 0.98)))
	name_vbox.add_child(name_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "Level %d Adventurer" % p["level"]
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.82))
	name_vbox.add_child(sub_lbl)

	# 4. Metric Value Pill
	var metric_pill = PanelContainer.new()
	var pill_st = StyleBoxFlat.new()
	pill_st.bg_color = Color(rank_color.r * 0.15, rank_color.g * 0.15, rank_color.b * 0.15, 0.85)
	pill_st.border_color = rank_color
	pill_st.set_border_width_all(1)
	pill_st.corner_radius_top_left = 6
	pill_st.corner_radius_top_right = 6
	pill_st.corner_radius_bottom_right = 6
	pill_st.corner_radius_bottom_left = 6
	pill_st.content_margin_left = 12
	pill_st.content_margin_right = 12
	pill_st.content_margin_top = 4
	pill_st.content_margin_bottom = 4
	metric_pill.add_theme_stylebox_override("panel", pill_st)

	var stat_lbl = Label.new()
	stat_lbl.text = _get_stat_string(p)
	stat_lbl.add_theme_font_size_override("font_size", 14)
	stat_lbl.add_theme_color_override("font_color", rank_color)
	metric_pill.add_child(stat_lbl)

	hbox.add_child(metric_pill)

	return row

func _on_guest_login_pressed() -> void:
	close_modal()
	SceneManager.change_scene(SceneManager.LOGIN)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		close_modal()
		get_viewport().set_input_as_handled()
