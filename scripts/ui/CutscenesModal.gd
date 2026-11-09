# res://scripts/ui/CutscenesModal.gd
extends ColorRect

signal cutscenes_closed

@onready var modal_card: PanelContainer = %ModalCard
@onready var close_btn: Button = %CloseBtn
@onready var summary_label: Label = %SummaryLabel
@onready var cutscenes_container: VBoxContainer = %CutscenesContainer

const CUTSCENES_DATA: Array[Dictionary] = [
	{
		"id": "prologue",
		"tag": "CHAPTER 0 • PROLOGUE",
		"title": "The Breach of Pythonia",
		"desc": "Before the darkness fell, Pythonia was peaceful under Princess Ada. An unknown entity ???? breaches the palace and abducts the sovereign. In 2026 at UiTM Tapah, Alex is pulled through his monitor into Variable Valley.",
		"thumb": "res://assets/cinematics/cinematic_intro_castle.jpg",
		"scene_path": "res://scenes/ui/CinematicIntro.tscn",
		"req_text": "Unlocked by default.",
		"unlocked_by_default": true
	},
	{
		"id": "plot_twist_ignis",
		"tag": "ACT II • THE PLOT TWIST",
		"title": "Shattered Malice • The Paladins' Curse",
		"desc": "Upon defeating Ignis-Py at the volcanic peak, all 5 bosses awaken from their curse and thank Alex. They reveal how they fought Lord SegFault, were defeated and cursed, and ask Alex to save Princess Ada and restore Pythonia.",
		"thumb": "res://assets/cinematics/cinematic_twist_five_generals.jpg",
		"scene_path": "res://scenes/ui/CutscenePlotTwist.tscn",
		"req_text": "Requires defeating Ignis-Py in Chapter 5.",
		"unlocked_by_default": false
	},
	{
		"id": "segfault_throne",
		"tag": "ACT III • THE CONFRONTATION",
		"title": "The Throne of Lord SegFault",
		"desc": "Alex breaches the grand throne room of the Obsidian Citadel. Princess Ada is suspended in a dark glitch stasis prism as Lord SegFault turns to face his challenger for the fate of Pythonia.",
		"thumb": "res://assets/cinematics/cinematic_segfault_throne_entrance.jpg",
		"scene_path": "res://scenes/ui/CutsceneThrone.tscn",
		"req_text": "Requires reaching Chapter 6 (The Obsidian Citadel).",
		"unlocked_by_default": false
	},
	{
		"id": "grand_epilogue",
		"tag": "FINALE • THE RESTORATION",
		"title": "The Grandmaster's Homecoming",
		"desc": "Lord SegFault collapses and is purged from memory. Alex catches Princess Ada from the falling stasis prism, and receives the sacred Codex of Python Mastery as Pythonia is restored.",
		"thumb": "res://assets/cinematics/cinematic_epilogue_alex_saves_ada.jpg",
		"scene_path": "res://scenes/ui/CutsceneEpilogue.tscn",
		"req_text": "Requires defeating Lord SegFault and completing the game.",
		"unlocked_by_default": false
	}
]

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(close_modal)

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_modal()

func open_modal() -> void:
	visible = true
	_animate_card_pop()
	_render_cutscenes()

func close_modal() -> void:
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(modal_card, "scale", Vector2(0.92, 0.92), 0.16)
	tw.parallel().tween_property(modal_card, "modulate:a", 0.0, 0.16)
	tw.tween_callback(func():
		visible = false
		modal_card.modulate.a = 1.0
		cutscenes_closed.emit()
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

func _is_cutscene_unlocked(info: Dictionary) -> bool:
	if SaveManager.is_dev_mode():
		return true
	if info.get("unlocked_by_default", false):
		return true
	
	var cid: String = info.get("id", "")
	var profile: Dictionary = SaveManager.user_profile
	var unlocked_level: int = int(profile.get("unlocked_level", 1))
	
	match cid:
		"plot_twist_ignis":
			return bool(profile.get("world5_boss_beaten", false)) or unlocked_level > 5 or bool(profile.get("cutscene_ignis_unlocked", false))
		"segfault_throne":
			return bool(profile.get("world6_unlocked", false)) or unlocked_level >= 6 or bool(profile.get("cutscene_segfault_unlocked", false))
		"grand_epilogue":
			return bool(profile.get("game_completed", false)) or bool(profile.get("cutscene_epilogue_unlocked", false))
		_:
			return false

func _render_cutscenes() -> void:
	for child in cutscenes_container.get_children():
		child.queue_free()
	
	var total_count: int = CUTSCENES_DATA.size()
	var unlocked_count: int = 0
	
	for info in CUTSCENES_DATA:
		if _is_cutscene_unlocked(info):
			unlocked_count += 1
	
	if summary_label:
		summary_label.text = "Unlocked: %d / %d Cinematic Memories" % [unlocked_count, total_count]
	
	for info in CUTSCENES_DATA:
		var card = _create_cutscene_card(info)
		cutscenes_container.add_child(card)

func _create_cutscene_card(info: Dictionary) -> Control:
	var is_unlocked: bool = _is_cutscene_unlocked(info)
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 110)
	
	var card_style = StyleBoxFlat.new()
	card_style.content_margin_left = 16
	card_style.content_margin_top = 12
	card_style.content_margin_right = 16
	card_style.content_margin_bottom = 12
	card_style.set_corner_radius_all(12)
	card_style.set_border_width_all(2)
	
	if is_unlocked:
		card_style.bg_color = Color(0.08, 0.11, 0.17, 0.95)
		card_style.border_color = Color(0.96, 0.78, 0.25, 0.85)
		card_style.shadow_color = Color(0, 0, 0, 0.6)
		card_style.shadow_size = 8
	else:
		card_style.bg_color = Color(0.05, 0.06, 0.09, 0.75)
		card_style.border_color = Color(0.3, 0.35, 0.45, 0.4)
	
	card.add_theme_stylebox_override("panel", card_style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	card.add_child(hbox)
	
	# 1. Thumbnail Container
	var thumb_box = Control.new()
	thumb_box.custom_minimum_size = Vector2(140, 86)
	hbox.add_child(thumb_box)
	
	var thumb_rect = TextureRect.new()
	thumb_rect.anchors_preset = Control.PRESET_FULL_RECT
	thumb_rect.anchor_right = 1.0
	thumb_rect.anchor_bottom = 1.0
	thumb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var thumb_path: String = info.get("thumb", "")
	if ResourceLoader.exists(thumb_path):
		thumb_rect.texture = load(thumb_path)
	
	if not is_unlocked:
		thumb_rect.modulate = Color(0.25, 0.28, 0.35, 0.5)
	thumb_box.add_child(thumb_rect)
	
	# Padlock or Play overlay on thumbnail
	var badge_label = Label.new()
	badge_label.anchors_preset = Control.PRESET_FULL_RECT
	badge_label.anchor_right = 1.0
	badge_label.anchor_bottom = 1.0
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_unlocked:
		badge_label.text = "▶"
		badge_label.add_theme_font_size_override("font_size", 24)
		badge_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4, 0.9))
		badge_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		badge_label.add_theme_constant_override("shadow_offset_y", 2)
	else:
		badge_label.text = "🔒"
		badge_label.add_theme_font_size_override("font_size", 28)
	thumb_box.add_child(badge_label)
	
	# 2. Text Info Column
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(text_vbox)
	
	var header_hbox = HBoxContainer.new()
	text_vbox.add_child(header_hbox)
	
	var tag_label = Label.new()
	tag_label.text = info.get("tag", "")
	tag_label.add_theme_font_size_override("font_size", 12)
	tag_label.add_theme_color_override("font_color", Color(0.38, 0.85, 0.95, 1) if is_unlocked else Color(0.6, 0.65, 0.75, 0.6))
	header_hbox.add_child(tag_label)
	
	var title_label = Label.new()
	title_label.text = info.get("title", "")
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.82, 1) if is_unlocked else Color(0.65, 0.68, 0.75, 0.7))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_y", 1)
	text_vbox.add_child(title_label)
	
	var desc_label = Label.new()
	desc_label.text = info.get("desc", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.84, 0.92, 0.85) if is_unlocked else Color(0.5, 0.55, 0.62, 0.6))
	text_vbox.add_child(desc_label)
	
	var status_hint = Label.new()
	status_hint.add_theme_font_size_override("font_size", 11)
	if is_unlocked:
		status_hint.text = "✓ Unlocked • Ready to replay"
		status_hint.add_theme_color_override("font_color", Color(0.3, 0.9, 0.55, 0.9))
	else:
		status_hint.text = "🔒 " + str(info.get("req_text", "Locked"))
		status_hint.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45, 0.85))
	text_vbox.add_child(status_hint)
	
	# 3. Action Button
	var btn_box = VBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(btn_box)
	
	var play_btn = Button.new()
	play_btn.custom_minimum_size = Vector2(130, 48)
	play_btn.focus_mode = Control.FOCUS_NONE
	
	var btn_style = StyleBoxFlat.new()
	btn_style.set_corner_radius_all(8)
	btn_style.set_border_width_all(2)
	
	if is_unlocked:
		btn_style.bg_color = Color(0.12, 0.42, 0.32, 0.95)
		btn_style.border_color = Color(0.35, 0.85, 0.55, 0.95)
		play_btn.text = "▶ Watch"
		play_btn.add_theme_color_override("font_color", Color(0.95, 1.0, 0.95, 1))
		play_btn.add_theme_font_size_override("font_size", 15)
		play_btn.add_theme_stylebox_override("normal", btn_style)
		
		var btn_hover = btn_style.duplicate() as StyleBoxFlat
		btn_hover.bg_color = Color(0.18, 0.58, 0.42, 1.0)
		btn_hover.border_color = Color(0.6, 1.0, 0.75, 1.0)
		play_btn.add_theme_stylebox_override("hover", btn_hover)
		
		var sc_path: String = info.get("scene_path", "")
		play_btn.pressed.connect(func():
			_play_cutscene(sc_path)
		)
	else:
		btn_style.bg_color = Color(0.14, 0.16, 0.22, 0.6)
		btn_style.border_color = Color(0.35, 0.4, 0.5, 0.4)
		play_btn.text = "🔒 Locked"
		play_btn.disabled = true
		play_btn.add_theme_color_override("font_color_disabled", Color(0.55, 0.6, 0.7, 0.5))
		play_btn.add_theme_font_size_override("font_size", 14)
		play_btn.add_theme_stylebox_override("disabled", btn_style)
	
	btn_box.add_child(play_btn)
	
	return card

func _play_cutscene(scene_path: String) -> void:
	if scene_path.is_empty():
		return
	visible = false
	SceneManager.change_scene_with_loading(scene_path)
