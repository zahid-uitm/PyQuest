# res://scripts/ui/BadgesModal.gd
extends ColorRect

signal badges_closed

@onready var modal_card: PanelContainer = %ModalCard
@onready var close_btn: Button = %CloseBtn
@onready var summary_label: Label = %SummaryLabel
@onready var tab_all_btn: Button = %TabAllBtn
@onready var tab_domain_btn: Button = %TabDomainBtn
@onready var tab_combat_btn: Button = %TabCombatBtn
@onready var tab_exploration_btn: Button = %TabExplorationBtn
@onready var tab_progression_btn: Button = %TabProgressionBtn
@onready var cards_grid: GridContainer = %CardsGrid

var current_category: String = "all"
var _active_tweens: Array[Tween] = []

func _ready() -> void:
	visible = false

	if close_btn:
		close_btn.pressed.connect(close_modal)

	if tab_all_btn:
		tab_all_btn.pressed.connect(func(): _switch_category("all"))
	if tab_domain_btn:
		tab_domain_btn.pressed.connect(func(): _switch_category("domain"))
	if tab_combat_btn:
		tab_combat_btn.pressed.connect(func(): _switch_category("combat"))
	if tab_exploration_btn:
		tab_exploration_btn.pressed.connect(func(): _switch_category("exploration"))
	if tab_progression_btn:
		tab_progression_btn.pressed.connect(func(): _switch_category("progression"))

func open_modal() -> void:
	visible = true
	_animate_card_pop()
	_update_tab_styles()
	_render_badges()

func close_modal() -> void:
	_clear_tweens()
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(modal_card, "scale", Vector2(0.92, 0.92), 0.16)
	tw.parallel().tween_property(modal_card, "modulate:a", 0.0, 0.16)
	tw.tween_callback(func():
		visible = false
		modal_card.modulate.a = 1.0
		badges_closed.emit()
	)

func _animate_card_pop() -> void:
	if not modal_card:
		return
	modal_card.pivot_offset = modal_card.size / 2.0
	modal_card.scale = Vector2(0.92, 0.92)
	modal_card.modulate.a = 0.0
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(modal_card, "scale", Vector2.ONE, 0.28)
	tw.parallel().tween_property(modal_card, "modulate:a", 1.0, 0.22)

func _switch_category(cat: String) -> void:
	AudioManager.play_sfx()
	current_category = cat
	_update_tab_styles()
	_render_badges()

func _update_tab_styles() -> void:
	var tabs = {
		"all": tab_all_btn,
		"domain": tab_domain_btn,
		"combat": tab_combat_btn,
		"exploration": tab_exploration_btn,
		"progression": tab_progression_btn
	}
	for cat_key in tabs.keys():
		var btn = tabs[cat_key]
		if not btn:
			continue
		var is_active = (cat_key == current_category)
		var st = StyleBoxFlat.new()
		st.corner_radius_top_left = 10
		st.corner_radius_top_right = 10
		st.corner_radius_bottom_right = 10
		st.corner_radius_bottom_left = 10
		st.content_margin_left = 16
		st.content_margin_right = 16
		st.content_margin_top = 8
		st.content_margin_bottom = 8

		if is_active:
			st.bg_color = Color(0.2, 0.72, 0.98, 0.95)
			st.border_width_bottom = 3
			st.border_color = Color(1.0, 1.0, 1.0, 0.9)
			btn.add_theme_color_override("font_color", Color(0.04, 0.08, 0.15))
		else:
			st.bg_color = Color(0.12, 0.16, 0.22, 0.85)
			st.border_width_left = 1
			st.border_width_top = 1
			st.border_width_right = 1
			st.border_width_bottom = 2
			st.border_color = Color(0.22, 0.28, 0.38, 0.7)
			btn.add_theme_color_override("font_color", Color(0.8, 0.88, 0.98))
		btn.add_theme_stylebox_override("normal", st)

func _clear_tweens() -> void:
	for tw in _active_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_active_tweens.clear()

func _render_badges() -> void:
	_clear_tweens()

	# Clear previous cards
	for child in cards_grid.get_children():
		child.queue_free()

	var unlocked_count = BadgeManager.get_unlocked_count()
	var total_count = BadgeManager.get_total_badges()
	var total_xp = BadgeManager.get_total_xp_earned()
	var pct = int((float(unlocked_count) / float(total_count)) * 100.0) if total_count > 0 else 0

	if summary_label:
		summary_label.text = "🏆 %d / %d Badges Unlocked (%d%%)  •  +%d Total XP Earned" % [
			unlocked_count, total_count, pct, total_xp
		]

	for badge_id in BadgeManager.BADGES_DATA.keys():
		var data = BadgeManager.BADGES_DATA[badge_id]
		if current_category != "all" and data["category"] != current_category:
			continue

		var is_unlocked = BadgeManager.is_badge_unlocked(badge_id)
		var progress = BadgeManager.get_badge_progress(badge_id)
		var card = _build_badge_card(badge_id, data, is_unlocked, progress)
		cards_grid.add_child(card)

func _build_badge_card(badge_id: String, data: Dictionary, is_unlocked: bool, progress: Dictionary) -> Control:
	var tier = data.get("tier", "bronze")
	var tier_color: Color
	match tier:
		"bronze": tier_color = Color(0.92, 0.60, 0.24)
		"silver": tier_color = Color(0.42, 0.78, 1.0)
		"gold":   tier_color = Color(1.0, 0.85, 0.28)
		"diamond":tier_color = Color(0.88, 0.50, 1.0)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(410, 134)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.pivot_offset = Vector2(205, 67)

	# Card StyleBox
	var st = StyleBoxFlat.new()
	st.corner_radius_top_left = 14
	st.corner_radius_top_right = 14
	st.corner_radius_bottom_right = 14
	st.corner_radius_bottom_left = 14
	st.set_border_width_all(2)
	st.content_margin_left = 16
	st.content_margin_right = 16
	st.content_margin_top = 12
	st.content_margin_bottom = 12

	if is_unlocked:
		st.bg_color = Color(0.09, 0.13, 0.20, 0.95)
		st.border_color = tier_color
		st.shadow_color = Color(tier_color.r, tier_color.g, tier_color.b, 0.35)
		st.shadow_size = 12
		st.shadow_offset = Vector2(0, 4)
	else:
		st.bg_color = Color(0.07, 0.08, 0.11, 0.85)
		st.border_color = Color(0.25, 0.3, 0.4, 0.6)
		st.shadow_color = Color(0, 0, 0, 0.4)
		st.shadow_size = 4
	card.add_theme_stylebox_override("panel", st)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	card.add_child(hbox)

	# 1. Badge Icon Medallion
	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(74, 74)
	icon_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon_container)

	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(74, 74)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.pivot_offset = Vector2(37, 37)

	if ResourceLoader.exists(data["icon_path"]):
		icon_rect.texture = load(data["icon_path"])

	if not is_unlocked:
		icon_rect.modulate = Color(0.35, 0.38, 0.45, 0.75) # Dimmed / locked
	icon_container.add_child(icon_rect)

	# 2. Details VBox
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	# Header row: Title + Tier pill
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)

	var title_lbl = Label.new()
	title_lbl.text = data["title"]
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color.WHITE if is_unlocked else Color(0.7, 0.75, 0.85))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)

	var tier_pill = Label.new()
	tier_pill.text = " %s " % tier.to_upper()
	tier_pill.add_theme_font_size_override("font_size", 11)
	tier_pill.add_theme_color_override("font_color", tier_color)
	var tp_st = StyleBoxFlat.new()
	tp_st.bg_color = Color(tier_color.r * 0.2, tier_color.g * 0.2, tier_color.b * 0.2, 0.8)
	tp_st.corner_radius_top_left = 6
	tp_st.corner_radius_top_right = 6
	tp_st.corner_radius_bottom_right = 6
	tp_st.corner_radius_bottom_left = 6
	tp_st.set_border_width_all(1)
	tp_st.border_color = tier_color
	tp_st.content_margin_left = 6
	tp_st.content_margin_right = 6
	tp_st.content_margin_top = 2
	tp_st.content_margin_bottom = 2
	tier_pill.add_theme_stylebox_override("panel", tp_st)
	header_hbox.add_child(tier_pill)

	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = data["description"]
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88) if is_unlocked else Color(0.5, 0.55, 0.65))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	# Bottom Status Row
	var footer_hbox = HBoxContainer.new()
	vbox.add_child(footer_hbox)

	if is_unlocked:
		var unl_lbl = Label.new()
		unl_lbl.text = "✓ UNLOCKED (+%d XP)" % int(data["xp_reward"])
		unl_lbl.add_theme_font_size_override("font_size", 12)
		unl_lbl.add_theme_color_override("font_color", Color(0.28, 0.95, 0.55))
		unl_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		footer_hbox.add_child(unl_lbl)
	else:
		var p_cur = progress["current"]
		var p_max = progress["max"]
		var p_pct = int(progress["percent"] * 100.0)

		var prog_lbl = Label.new()
		prog_lbl.text = "🔒 %d / %d (%d%%)  •  Reward: +%d XP" % [p_cur, p_max, p_pct, int(data["xp_reward"])]
		prog_lbl.add_theme_font_size_override("font_size", 11)
		prog_lbl.add_theme_color_override("font_color", Color(0.85, 0.7, 0.3))
		prog_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		footer_hbox.add_child(prog_lbl)

	# Card Animations
	# 1. Subtle breathing animation for unlocked badges
	if is_unlocked:
		var breathe_tw = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		breathe_tw.tween_property(icon_rect, "scale", Vector2(1.06, 1.06), 1.6)
		breathe_tw.tween_property(icon_rect, "scale", Vector2.ONE, 1.6)
		_active_tweens.append(breathe_tw)

	# 2. Interactive hover spring bounce
	card.mouse_entered.connect(func():
		var tw_in = card.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_in.tween_property(card, "scale", Vector2(1.025, 1.025), 0.18)
	)
	card.mouse_exited.connect(func():
		var tw_out = card.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw_out.tween_property(card, "scale", Vector2.ONE, 0.18)
	)

	return card
