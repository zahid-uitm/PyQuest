# res://scripts/core/BadgeManager.gd
extends Node

signal badge_unlocked(badge_id: String, badge_data: Dictionary)

const BADGES_DATA: Dictionary = {
	# -------------------------------------------------------------------------
	# 1. DOMAIN MASTERY BADGES (Python Knowledge)
	# -------------------------------------------------------------------------
	"variable_pioneer": {
		"title": "Variable Pioneer",
		"description": "Awaken all 3 Variable Valley Shrines (Integers, Strings, Booleans).",
		"category": "domain",
		"tier": "bronze",
		"xp_reward": 100,
		"icon_path": "res://assets/sprites/badges/badge_variable_pioneer.png",
		"max_progress": 3
	},
	"logic_architect": {
		"title": "Logic Architect",
		"description": "Master all Shrines in World 2 (if/elif/else, for loops, sentinel while loops).",
		"category": "domain",
		"tier": "silver",
		"xp_reward": 150,
		"icon_path": "res://assets/sprites/badges/badge_logic_architect.png",
		"max_progress": 3
	},
	"modular_sorcerer": {
		"title": "Modular Sorcerer",
		"description": "Master all Shrines in World 3 (def declarations, parameters, return values).",
		"category": "domain",
		"tier": "gold",
		"xp_reward": 200,
		"icon_path": "res://assets/sprites/badges/badge_modular_sorcerer.png",
		"max_progress": 3
	},
	"sequence_master": {
		"title": "Sequence Master",
		"description": "Master all Shrines in World 4 (0-based indexing, negative indices, slices).",
		"category": "domain",
		"tier": "gold",
		"xp_reward": 250,
		"icon_path": "res://assets/sprites/badges/badge_sequence_master.png",
		"max_progress": 3
	},
	"grandmaster": {
		"title": "Python Grandmaster",
		"description": "Awaken all 12 Ancient Knowledge Shrines across the entire realm.",
		"category": "domain",
		"tier": "diamond",
		"xp_reward": 500,
		"icon_path": "res://assets/sprites/badges/badge_grandmaster.png",
		"max_progress": 12
	},

	# -------------------------------------------------------------------------
	# 2. COMBAT & CODE EXECUTION BADGES
	# -------------------------------------------------------------------------
	"first_blood": {
		"title": "First Blood",
		"description": "Vanquish your first World Boss (NullByte in Variable Valley).",
		"category": "combat",
		"tier": "bronze",
		"xp_reward": 50,
		"icon_path": "res://assets/sprites/badges/badge_first_blood.png",
		"max_progress": 1
	},
	"flawless_syntax": {
		"title": "Flawless Syntax",
		"description": "Defeat any World Boss with a 3-Star Rating (perfect accuracy).",
		"category": "combat",
		"tier": "gold",
		"xp_reward": 200,
		"icon_path": "res://assets/sprites/badges/badge_flawless_syntax.png",
		"max_progress": 1
	},
	"pure_instinct": {
		"title": "Pure Instinct",
		"description": "Defeat a World Boss without asking Master PyWizard for any Hints.",
		"category": "combat",
		"tier": "gold",
		"xp_reward": 250,
		"icon_path": "res://assets/sprites/badges/badge_pure_instinct.png",
		"max_progress": 1
	},
	"boss_slayer": {
		"title": "Boss Slayer",
		"description": "Vanquish all 4 World Bosses across the PyQuest expedition.",
		"category": "combat",
		"tier": "diamond",
		"xp_reward": 500,
		"icon_path": "res://assets/sprites/badges/badge_boss_slayer.png",
		"max_progress": 4
	},
	"code_streak": {
		"title": "Code Streak",
		"description": "Answer 5 battle code questions correctly in a row without a mistake.",
		"category": "combat",
		"tier": "silver",
		"xp_reward": 150,
		"icon_path": "res://assets/sprites/badges/badge_code_streak.png",
		"max_progress": 5
	},

	# -------------------------------------------------------------------------
	# 3. WORLD EXPLORATION & QUESTING BADGES
	# -------------------------------------------------------------------------
	"realm_explorer": {
		"title": "Realm Explorer",
		"description": "Journey through and unlock all 4 distinct biomes in PyQuest.",
		"category": "exploration",
		"tier": "silver",
		"xp_reward": 100,
		"icon_path": "res://assets/sprites/badges/badge_realm_explorer.png",
		"max_progress": 4
	},
	"town_benefactor": {
		"title": "Town Benefactor",
		"description": "Converse with and assist all 12 Quest NPCs across all four worlds.",
		"category": "exploration",
		"tier": "silver",
		"xp_reward": 200,
		"icon_path": "res://assets/sprites/badges/badge_town_benefactor.png",
		"max_progress": 12
	},
	"pathfinder": {
		"title": "Pathfinder",
		"description": "Unlock all World puzzle barriers (Chasm Bridges, Vault Seals, Matrix Gates).",
		"category": "exploration",
		"tier": "silver",
		"xp_reward": 150,
		"icon_path": "res://assets/sprites/badges/badge_pathfinder.png",
		"max_progress": 6
	},
	"treasure_hunter": {
		"title": "Treasure Hunter",
		"description": "Discover and unlock ancient hidden treasure chests across the realm.",
		"category": "exploration",
		"tier": "bronze",
		"xp_reward": 100,
		"icon_path": "res://assets/sprites/badges/badge_treasure_hunter.png",
		"max_progress": 3
	},

	# -------------------------------------------------------------------------
	# 4. MILESTONES & GROWTH BADGES
	# -------------------------------------------------------------------------
	"rising_apprentice": {
		"title": "Rising Apprentice",
		"description": "Attain Player Level 3 on your coding quest.",
		"category": "progression",
		"tier": "bronze",
		"xp_reward": 50,
		"icon_path": "res://assets/sprites/badges/badge_rising_apprentice.png",
		"max_progress": 3
	},
	"archmage": {
		"title": "Archmage of Code",
		"description": "Ascend to the maximum Player Level 10 (5,000+ Total XP).",
		"category": "progression",
		"tier": "diamond",
		"xp_reward": 500,
		"icon_path": "res://assets/sprites/badges/badge_archmage.png",
		"max_progress": 10
	}
}

# Notification popup UI references
var _popup_layer: CanvasLayer
var _popup_banner: PanelContainer
var _badge_icon: TextureRect
var _sub_label: Label
var _title_label: Label
var _desc_label: Label
var _reward_label: Label

var _popup_queue: Array[Dictionary] = []
var _is_showing_popup: bool = false
var _active_tween: Tween

func _ready() -> void:
	_create_badge_popup_ui()
	# Check immediately upon startup in case existing save matches badges
	call_deferred("check_all_badges")

# -----------------------------------------------------------------------------
# BADGE UNLOCK TOAST POPUP UI SETUP
# -----------------------------------------------------------------------------
func _create_badge_popup_ui() -> void:
	_popup_layer = CanvasLayer.new()
	_popup_layer.name = "BadgeUnlockOverlay"
	_popup_layer.layer = 125
	add_child(_popup_layer)

	_popup_banner = PanelContainer.new()
	_popup_banner.name = "BadgeToastPill"
	_popup_banner.custom_minimum_size = Vector2(460, 78)
	_popup_banner.pivot_offset = Vector2(230, 39)
	
	# Rounded capsule style matching sleek achievement toast
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.10, 0.15, 0.96)
	st.border_width_left = 2
	st.border_width_top = 2
	st.border_width_right = 2
	st.border_width_bottom = 2
	st.border_color = Color(0.98, 0.82, 0.28, 0.9)
	st.corner_radius_top_left = 39
	st.corner_radius_top_right = 39
	st.corner_radius_bottom_right = 39
	st.corner_radius_bottom_left = 39
	st.shadow_color = Color(0, 0, 0, 0.75)
	st.shadow_size = 20
	st.shadow_offset = Vector2(0, 7)
	st.content_margin_left = 16
	st.content_margin_right = 22
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	_popup_banner.add_theme_stylebox_override("panel", st)

	# Position at top center
	_popup_banner.anchor_top = 0.0
	_popup_banner.anchor_bottom = 0.0
	_popup_banner.anchor_left = 0.5
	_popup_banner.anchor_right = 0.5
	_popup_banner.offset_left = -230
	_popup_banner.offset_right = 230
	_popup_banner.offset_top = -120 # Off-screen
	_popup_banner.offset_bottom = -42

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	_popup_banner.add_child(hbox)

	# 1. Hero Badge Medallion (Larger 58x58 with tier frame)
	_badge_icon = TextureRect.new()
	_badge_icon.custom_minimum_size = Vector2(58, 58)
	_badge_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_badge_icon.pivot_offset = Vector2(29, 29)
	hbox.add_child(_badge_icon)

	# 2. Text VBox
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	_sub_label = Label.new()
	_sub_label.text = "🏆 BADGE UNLOCKED"
	_sub_label.add_theme_font_size_override("font_size", 12)
	_sub_label.add_theme_color_override("font_color", Color(0.98, 0.85, 0.35))
	vbox.add_child(_sub_label)

	_title_label = Label.new()
	_title_label.text = "Badge Name"
	_title_label.add_theme_font_size_override("font_size", 17)
	_title_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_title_label)

	_desc_label = Label.new()
	_desc_label.text = "Description here"
	_desc_label.add_theme_font_size_override("font_size", 12)
	_desc_label.add_theme_color_override("font_color", Color(0.72, 0.80, 0.90))
	_desc_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vbox.add_child(_desc_label)

	# 3. XP Reward Pill tag on the right
	_reward_label = Label.new()
	_reward_label.text = "+200 XP"
	_reward_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_reward_label.add_theme_font_size_override("font_size", 13)
	_reward_label.add_theme_color_override("font_color", Color(0.98, 0.85, 0.35))
	
	var r_st = StyleBoxFlat.new()
	r_st.bg_color = Color(0.18, 0.14, 0.05, 0.92)
	r_st.border_width_left = 1
	r_st.border_width_top = 1
	r_st.border_width_right = 1
	r_st.border_width_bottom = 1
	r_st.border_color = Color(0.95, 0.78, 0.25, 0.85)
	r_st.corner_radius_top_left = 12
	r_st.corner_radius_top_right = 12
	r_st.corner_radius_bottom_right = 12
	r_st.corner_radius_bottom_left = 12
	r_st.content_margin_left = 10
	r_st.content_margin_right = 10
	r_st.content_margin_top = 4
	r_st.content_margin_bottom = 4
	_reward_label.add_theme_stylebox_override("panel", r_st)
	hbox.add_child(_reward_label)

	_popup_layer.add_child(_popup_banner)

# -----------------------------------------------------------------------------
# CORE BADGE MANAGEMENT API
# -----------------------------------------------------------------------------
func is_badge_unlocked(badge_id: String) -> bool:
	var unlocked: Array = SaveManager.user_profile.get("badges", [])
	return badge_id in unlocked

func get_unlocked_count() -> int:
	var unlocked: Array = SaveManager.user_profile.get("badges", [])
	return unlocked.size()

func get_total_badges() -> int:
	return BADGES_DATA.size()

func get_total_xp_earned() -> int:
	var total = 0
	var unlocked: Array = SaveManager.user_profile.get("badges", [])
	for b_id in unlocked:
		if BADGES_DATA.has(b_id):
			total += int(BADGES_DATA[b_id].get("xp_reward", 0))
	return total

func unlock_badge(badge_id: String) -> bool:
	if not BADGES_DATA.has(badge_id):
		return false
	if is_badge_unlocked(badge_id):
		return false

	var data = BADGES_DATA[badge_id]
	
	# Register into player profile
	var badges: Array = SaveManager.user_profile.get("badges", [])
	badges.append(badge_id)
	SaveManager.user_profile["badges"] = badges

	# Timestamp
	var times: Dictionary = SaveManager.user_profile.get("badges_unlocked_at", {})
	times[badge_id] = Time.get_datetime_string_from_system()
	SaveManager.user_profile["badges_unlocked_at"] = times

	# Grant XP bonus
	var xp_bonus = int(data.get("xp_reward", 0))
	var cur_xp = int(SaveManager.user_profile.get("xp", 0)) + xp_bonus
	SaveManager.user_profile["xp"] = cur_xp
	SaveManager.user_profile["player_level"] = max(1, int(cur_xp / 500) + 1)

	# Save profile locally and sync to Firebase
	SaveManager.save_local_profile()
	if not SaveManager.is_guest() and FirebaseManager.is_authenticated():
		FirebaseManager.write_player_profile(SaveManager.user_profile)

	badge_unlocked.emit(badge_id, data)

	# Queue for Google Play Games animated toast
	_popup_queue.append(data)
	if not _is_showing_popup:
		_process_next_popup()

	return true

# -----------------------------------------------------------------------------
# GOOGLE PLAY GAMES ANIMATED TOAST BANNER
# -----------------------------------------------------------------------------
func _process_next_popup() -> void:
	if _popup_queue.is_empty():
		_is_showing_popup = false
		return

	_is_showing_popup = true
	var data: Dictionary = _popup_queue.pop_front()

	# Populate UI
	_title_label.text = data["title"]
	_desc_label.text = data["description"]
	_reward_label.text = "+%d XP" % int(data["xp_reward"])

	if ResourceLoader.exists(data["icon_path"]):
		_badge_icon.texture = load(data["icon_path"])
		_badge_icon.visible = true
	else:
		_badge_icon.visible = false

	# Play celebration sound
	AudioManager.play_badge_unlock()

	# Border tint based on badge tier
	var tier = data.get("tier", "bronze")
	var st = _popup_banner.get_theme_stylebox("panel") as StyleBoxFlat
	if st:
		match tier:
			"bronze": st.border_color = Color(0.9, 0.58, 0.22, 0.9)
			"silver": st.border_color = Color(0.4, 0.75, 1.0, 0.9)
			"gold":   st.border_color = Color(1.0, 0.85, 0.25, 0.95)
			"diamond":st.border_color = Color(0.85, 0.45, 1.0, 0.95)

	# Animation Sequence
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	_active_tween = create_tween()
	
	# Reset states
	_popup_banner.offset_top = -120
	_popup_banner.offset_bottom = -42
	_badge_icon.scale = Vector2(0.2, 0.2)
	_badge_icon.rotation_degrees = -25.0

	# 1. Slide down smoothly with back ease
	_active_tween.parallel().tween_property(_popup_banner, "offset_top", 24.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.parallel().tween_property(_popup_banner, "offset_bottom", 102.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 2. Hero Badge icon pops in with glorious bounce and straightens
	_active_tween.parallel().tween_property(_badge_icon, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.parallel().tween_property(_badge_icon, "rotation_degrees", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 3. Hold banner on-screen for 5.0 seconds so player has ample time to admire the badge
	_active_tween.tween_interval(5.0)

	# 4. Slide back up out of screen
	_active_tween.parallel().tween_property(_popup_banner, "offset_top", -120.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_active_tween.parallel().tween_property(_popup_banner, "offset_bottom", -42.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_active_tween.parallel().tween_property(_badge_icon, "scale", Vector2(0.4, 0.4), 0.35)

	_active_tween.tween_callback(func():
		_process_next_popup()
	)

# -----------------------------------------------------------------------------
# REAL-TIME PROGRESS CALCULATION
# -----------------------------------------------------------------------------
func get_badge_progress(badge_id: String) -> Dictionary:
	var prof = SaveManager.user_profile
	var cur = 0
	var max_v = BADGES_DATA[badge_id]["max_progress"]
	var stars_dict = prof.get("level_stars", {})

	match badge_id:
		"variable_pioneer":
			cur = prof.get("w1_shrines", []).size()
		"logic_architect":
			cur = prof.get("w2_shrines", []).size()
		"modular_sorcerer":
			cur = prof.get("w3_shrines", []).size()
		"sequence_master":
			cur = prof.get("w4_shrines", []).size()
		"grandmaster":
			cur = prof.get("w1_shrines", []).size() + prof.get("w2_shrines", []).size() + prof.get("w3_shrines", []).size() + prof.get("w4_shrines", []).size()
		"first_blood":
			cur = 1 if int(stars_dict.get("1", 0)) > 0 else 0
		"flawless_syntax":
			for s in stars_dict.values():
				if int(s) >= 3:
					cur = 1
					break
		"pure_instinct":
			cur = 1 if is_badge_unlocked("pure_instinct") else 0
		"boss_slayer":
			var count = 0
			for lvl_str in ["1", "2", "3", "4"]:
				if int(stars_dict.get(lvl_str, 0)) > 0:
					count += 1
			cur = count
		"code_streak":
			cur = 5 if is_badge_unlocked("code_streak") else int(prof.get("max_code_streak", 0))
		"realm_explorer":
			cur = int(prof.get("unlocked_level", 1))
		"town_benefactor":
			cur = prof.get("w1_npcs", []).size() + prof.get("w2_npcs_helped", []).size() + prof.get("w3_npcs_helped", []).size() + prof.get("w4_npcs_helped", []).size()
		"pathfinder":
			cur = prof.get("w2_bridges", []).size() + prof.get("w3_seals", []).size() + prof.get("w4_gates", []).size()
		"treasure_hunter":
			cur = prof.get("chests_opened", []).size()
		"rising_apprentice":
			cur = int(prof.get("player_level", 1))
		"archmage":
			cur = int(prof.get("player_level", 1))

	cur = min(cur, max_v)
	var pct = float(cur) / float(max_v) if max_v > 0 else 0.0
	return {
		"current": cur,
		"max": max_v,
		"percent": clamp(pct, 0.0, 1.0)
	}

# -----------------------------------------------------------------------------
# GLOBAL IN-GAME CONDITION EVALUATOR
# -----------------------------------------------------------------------------
func check_all_badges(context: Dictionary = {}) -> void:
	var prof = SaveManager.user_profile

	# 1. Variable Pioneer (W1 Shrines >= 3)
	if prof.get("w1_shrines", []).size() >= 3:
		unlock_badge("variable_pioneer")

	# 2. Logic Architect (W2 Shrines >= 3)
	if prof.get("w2_shrines", []).size() >= 3:
		unlock_badge("logic_architect")

	# 3. Modular Sorcerer (W3 Shrines >= 3)
	if prof.get("w3_shrines", []).size() >= 3:
		unlock_badge("modular_sorcerer")

	# 4. Sequence Master (W4 Shrines >= 3)
	if prof.get("w4_shrines", []).size() >= 3:
		unlock_badge("sequence_master")

	# 5. Grandmaster (All 12 shrines)
	var total_shrines = prof.get("w1_shrines", []).size() + prof.get("w2_shrines", []).size() + prof.get("w3_shrines", []).size() + prof.get("w4_shrines", []).size()
	if total_shrines >= 12:
		unlock_badge("grandmaster")

	# 6. First Blood (Beat World 1 Boss)
	var stars = prof.get("level_stars", {})
	if int(stars.get("1", 0)) > 0:
		unlock_badge("first_blood")

	# 7. Flawless Syntax (Any level 3 stars)
	for s in stars.values():
		if int(s) >= 3:
			unlock_badge("flawless_syntax")
			break

	# 8. Pure Instinct (Context checked in combat when won with 0 hints used)
	if context.get("no_hints_used", false):
		unlock_badge("pure_instinct")

	# 9. Boss Slayer (All 4 World Bosses defeated)
	var all_bosses_defeated = true
	for lvl in ["1", "2", "3", "4"]:
		if int(stars.get(lvl, 0)) <= 0:
			all_bosses_defeated = false
			break
	if all_bosses_defeated:
		unlock_badge("boss_slayer")

	# 10. Code Streak (5 correct in a row)
	if context.get("code_streak", 0) >= 5 or int(prof.get("max_code_streak", 0)) >= 5:
		unlock_badge("code_streak")

	# 11. Realm Explorer (All 4 worlds unlocked)
	if int(prof.get("unlocked_level", 1)) >= 4:
		unlock_badge("realm_explorer")

	# 12. Town Benefactor (12 NPCs helped)
	var total_npcs = prof.get("w1_npcs", []).size() + prof.get("w2_npcs_helped", []).size() + prof.get("w3_npcs_helped", []).size() + prof.get("w4_npcs_helped", []).size()
	if total_npcs >= 12:
		unlock_badge("town_benefactor")

	# 13. Pathfinder (2 bridges + 2 seals + 2 gates = 6)
	var barriers = prof.get("w2_bridges", []).size() + prof.get("w3_seals", []).size() + prof.get("w4_gates", []).size()
	if barriers >= 6:
		unlock_badge("pathfinder")

	# 14. Treasure Hunter (>= 3 chests opened)
	if prof.get("chests_opened", []).size() >= 3:
		unlock_badge("treasure_hunter")

	# 15. Rising Apprentice (Level >= 3)
	if int(prof.get("player_level", 1)) >= 3:
		unlock_badge("rising_apprentice")

	# 16. Archmage of Code (Level >= 10)
	if int(prof.get("player_level", 1)) >= 10:
		unlock_badge("archmage")
