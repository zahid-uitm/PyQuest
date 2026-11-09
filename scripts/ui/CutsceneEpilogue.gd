# res://scripts/ui/CutsceneEpilogue.gd
extends Control

signal epilogue_completed

@onready var bg_stage_segfault_fall: TextureRect = $Stages/StageSegfaultFall
@onready var bg_stage_prison_break: TextureRect = $Stages/StagePrisonBreak
@onready var bg_stage_alex_saves_ada: TextureRect = $Stages/StageAlexSavesAda
@onready var bg_stage_pythonia_restored: TextureRect = $Stages/StagePythoniaRestored
@onready var bg_stage_codex_restoration: TextureRect = $Stages/StageCodexRestoration

@onready var gold_particles: CPUParticles2D = $VFX/GoldParticles
@onready var flash_rect: ColorRect = $VFX/FlashRect

@onready var narrator_panel: PanelContainer = $HUD/NarratorPanel
@onready var narrator_act_label: Label = $HUD/NarratorPanel/Margin/VBox/ActLabel
@onready var narrator_text_label: RichTextLabel = $HUD/NarratorPanel/Margin/VBox/NarrationText

@onready var skip_button: Button = $HUD/SkipButton
@onready var bottom_dialog_bar: CanvasLayer = $BottomDialogBar

# Celebration End Screen
@onready var celebration_overlay: Control = $HUD/CelebrationOverlay
@onready var celebration_card: PanelContainer = $HUD/CelebrationOverlay/Center/Card
@onready var confetti_particles: CPUParticles2D = $HUD/CelebrationOverlay/ConfettiParticles
@onready var stars_label: Label = $HUD/CelebrationOverlay/Center/Card/VBox/StatsBox/StarsLabel
@onready var badges_label: Label = $HUD/CelebrationOverlay/Center/Card/VBox/StatsBox/BadgesLabel

@onready var menu_btn: Button = $HUD/CelebrationOverlay/Center/Card/VBox/ButtonHBox/MenuBtn
@onready var map_btn: Button = $HUD/CelebrationOverlay/Center/Card/VBox/ButtonHBox/MapBtn
@onready var badges_btn: Button = $HUD/CelebrationOverlay/Center/Card/VBox/ButtonHBox/BadgesBtn

var _skipped: bool = false
var _narrative_tween: Tween = null

const DIALOG_EPILOGUE: Array = [
	{
		"side": "left",
		"name": "Princess Ada",
		"left_name": "Princess Ada",
		"right_name": "Adventurer Alex",
		"left_portrait": "res://assets/sprites/portraits/portrait_princess_ada.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_alex_calm.png",
		"show_right": false,
		"mood_tag": "GRATITUDE",
		"theme_color": Color("#FCD34D"),
		"text": "Alex... you saved our lives, our kingdom, and our entire world from eternal corruption. On behalf of all Pythonia, we will never forget your courage."
	},
	{
		"side": "right",
		"name": "General Ignis-Py",
		"left_name": "Princess Ada",
		"right_name": "General Ignis-Py",
		"left_portrait": "res://assets/sprites/portraits/portrait_princess_ada.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_ignis.png",
		"show_right": true,
		"mood_tag": "HONOR",
		"theme_color": Color("#FB7185"),
		"text": "By the ancient fire! All Five Generals salute you! You began as a stranded coder from UiTM Tapah—and now stand before us as the greatest Grandmaster Pythonia has ever known!"
	},
	{
		"side": "left",
		"name": "Princess Ada",
		"left_name": "Princess Ada",
		"right_name": "General Ignis-Py",
		"left_portrait": "res://assets/sprites/portraits/portrait_princess_ada.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_ignis.png",
		"show_right": true,
		"mood_tag": "CORONATION",
		"theme_color": Color("#38BDF8"),
		"text": "By royal decree of Pythonia, I bestow upon you the sacred [color=#FCD34D][b]Codex of Python Mastery[/b][/color]! Within its pages rests the living syntax of variables, logic, loops, functions, and data structures. You have truly mastered Python, Alex."
	},
	{
		"side": "right",
		"name": "Adventurer Alex",
		"left_name": "Princess Ada",
		"right_name": "Adventurer Alex",
		"left_portrait": "res://assets/sprites/portraits/portrait_princess_ada.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_alex_smile.png",
		"show_right": true,
		"mood_tag": "HOMECOMING",
		"theme_color": Color("#10B981"),
		"text": "Thank you, Princess Ada! Thank you, Generals! Pythonia taught me that every challenge can be solved with patience and clean logic. I will carry the Codex with pride back home to UiTM Tapah!"
	}
]

func _ready() -> void:
	AudioManager.play_bgm_by_path("res://assets/audio/mainmenu_music.mp3", 0.01)
	_setup_visual_elements()
	_start_cutscene()

func _setup_visual_elements() -> void:
	bg_stage_segfault_fall.visible = true
	bg_stage_segfault_fall.modulate.a = 1.0
	bg_stage_segfault_fall.pivot_offset = Vector2(960, 540)
	bg_stage_segfault_fall.scale = Vector2.ONE
	
	bg_stage_prison_break.visible = true
	bg_stage_prison_break.modulate.a = 0.0
	bg_stage_prison_break.pivot_offset = Vector2(960, 540)
	bg_stage_prison_break.scale = Vector2.ONE
	
	bg_stage_alex_saves_ada.visible = true
	bg_stage_alex_saves_ada.modulate.a = 0.0
	bg_stage_alex_saves_ada.pivot_offset = Vector2(960, 540)
	bg_stage_alex_saves_ada.scale = Vector2.ONE
	
	bg_stage_pythonia_restored.visible = true
	bg_stage_pythonia_restored.modulate.a = 0.0
	bg_stage_pythonia_restored.pivot_offset = Vector2(960, 540)
	bg_stage_pythonia_restored.scale = Vector2.ONE
	
	bg_stage_codex_restoration.visible = true
	bg_stage_codex_restoration.modulate.a = 0.0
	bg_stage_codex_restoration.pivot_offset = Vector2(960, 540)
	bg_stage_codex_restoration.scale = Vector2.ONE
	
	flash_rect.visible = false
	flash_rect.modulate.a = 0.0
	narrator_panel.visible = false
	
	if celebration_overlay:
		celebration_overlay.visible = false
		celebration_overlay.modulate.a = 0.0
	
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	
	if menu_btn:
		menu_btn.pressed.connect(func():
			SceneManager.change_scene_with_loading(SceneManager.MAIN_MENU)
		)
	if map_btn:
		map_btn.pressed.connect(func():
			SceneManager.change_scene_with_loading(SceneManager.LEVEL_SELECT)
		)
	if badges_btn:
		badges_btn.pressed.connect(func():
			SceneManager.change_scene_with_loading(SceneManager.LEVEL_SELECT)
		)

func _start_cutscene() -> void:
	# =========================================================================
	# SCENE 1: The Fall of Lord SegFault (POV behind Alex & 5 Generals)
	# =========================================================================
	_show_narration("ACT IV • THE COLLAPSE OF NULL", 
		"Lord SegFault falls to his knees as his corrupt null-pointer core dissolves into fading glitch sparks. The dark sovereign has been purged from Pythonia forever!")
	
	var zoom_tw1 = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_tw1.tween_property(bg_stage_segfault_fall, "scale", Vector2(1.04, 1.04), 4.5)
	
	await get_tree().create_timer(4.5).timeout
	if _skipped: return
	
	# =========================================================================
	# SCENE 2: The Shattering of the Stasis Prism (Princess Ada falls)
	# =========================================================================
	_shake_screen(6.0, 0.7)
	AudioManager.play_sfx()
	
	var tw_break = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_break.tween_property(bg_stage_segfault_fall, "modulate:a", 0.0, 0.8)
	tw_break.tween_property(bg_stage_prison_break, "modulate:a", 1.0, 0.8)
	
	var zoom_tw2 = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_tw2.tween_property(bg_stage_prison_break, "scale", Vector2(1.03, 1.03), 4.2)
	
	_show_narration("FREEDOM FROM STASIS", 
		"With SegFault's destruction, the dark chains snap and the glitch stasis prism shatters into a thousand radiant crystal shards! Princess Ada freefalls through the air from the high vaulted ceiling...")
	
	await get_tree().create_timer(4.2).timeout
	if _skipped: return
	
	# =========================================================================
	# SCENE 3: Alex Catches Princess Ada Just in Time!
	# =========================================================================
	_shake_screen(4.0, 0.5)
	AudioManager.play_sfx()
	
	# Soft golden flash
	var flash_tw1 = create_tween()
	flash_rect.visible = true
	flash_rect.modulate = Color(1, 0.95, 0.7, 0.6)
	flash_tw1.tween_property(flash_rect, "modulate:a", 0.0, 0.5)
	
	var tw_catch = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_catch.tween_property(bg_stage_prison_break, "modulate:a", 0.0, 0.8)
	tw_catch.tween_property(bg_stage_alex_saves_ada, "modulate:a", 1.0, 0.8)
	
	var zoom_tw3 = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_tw3.tween_property(bg_stage_alex_saves_ada, "scale", Vector2(1.03, 1.03), 4.5)
	
	_show_narration("JUST IN TIME", 
		"Dashing across the sanctum floor with heroic speed, Alex catches the Princess safely in his arms just before she hits the ground. Safe at last, Princess Ada looks up into his eyes with tears of joy and relief!")
	
	await get_tree().create_timer(4.5).timeout
	if _skipped: return
	
	# =========================================================================
	# SCENE 4: Overview of Pythonia Restored
	# =========================================================================
	AudioManager.play_sfx(AudioManager.SFX_SHRINE_AWAKEN)
	if gold_particles:
		gold_particles.restart()
		gold_particles.emitting = true
	
	var tw_restore = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_restore.tween_property(bg_stage_alex_saves_ada, "modulate:a", 0.0, 1.0)
	tw_restore.tween_property(bg_stage_pythonia_restored, "modulate:a", 1.0, 1.0)
	
	var zoom_tw4 = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_tw4.tween_property(bg_stage_pythonia_restored, "scale", Vector2(1.04, 1.04), 5.0)
	
	_show_narration("RESTORATION OF PYTHONIA", 
		"The dark glitch storm recedes across all five realms. Triumphant dawn sunlight floods the valleys, ancient runic arches hum with purified code, and Pythonia breathes free once more.")
	
	await get_tree().create_timer(5.0).timeout
	if _skipped: return
	
	# =========================================================================
	# SCENE 5: The Balcony Terrace & The Codex of Python Mastery
	# =========================================================================
	_hide_narration()
	
	var tw_codex = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_codex.tween_property(bg_stage_pythonia_restored, "modulate:a", 0.0, 1.0)
	tw_codex.tween_property(bg_stage_codex_restoration, "modulate:a", 1.0, 1.0)
	
	await get_tree().create_timer(1.2).timeout
	if _skipped: return
	
	# Play bottom dialogue with Princess Ada, Ignis-Py, and Alex
	await _play_dialog_and_wait(DIALOG_EPILOGUE)
	if _skipped: return
	
	# =========================================================================
	# SCENE 6 & 7: Congratulations Victory Overlay & "THE END"
	# =========================================================================
	_show_congratulations_screen()

func _play_dialog_and_wait(dialog_lines: Array) -> void:
	if not bottom_dialog_bar or not bottom_dialog_bar.has_method("play_sequence"):
		return
	bottom_dialog_bar.play_sequence(dialog_lines)
	await bottom_dialog_bar.dialog_finished

func _show_narration(act_title: String, body_text: String) -> void:
	narrator_panel.visible = true
	narrator_panel.modulate.a = 0.0
	narrator_act_label.text = act_title
	narrator_text_label.text = body_text
	narrator_text_label.visible_ratio = 0.0
	
	if _narrative_tween and _narrative_tween.is_valid():
		_narrative_tween.kill()
	
	_narrative_tween = create_tween()
	_narrative_tween.tween_property(narrator_panel, "modulate:a", 1.0, 0.3)
	_narrative_tween.tween_property(narrator_text_label, "visible_ratio", 1.0, 1.0)

func _hide_narration() -> void:
	if narrator_panel.visible:
		var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(narrator_panel, "modulate:a", 0.0, 0.3)
		tw.tween_callback(func(): narrator_panel.visible = false)

func _shake_screen(intensity: float, duration: float) -> void:
	var tw = create_tween()
	var steps: int = int(duration / 0.05)
	for i in range(steps):
		var damp: float = 1.0 - (float(i) / float(steps))
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)) * damp
		tw.tween_property(self, "position", offset, 0.05)
	tw.tween_property(self, "position", Vector2.ZERO, 0.05)

func _show_congratulations_screen() -> void:
	SaveManager.user_profile["game_completed"] = true
	SaveManager.user_profile["cutscene_epilogue_unlocked"] = true
	SaveManager.user_profile["current_level"] = 6
	SaveManager.save_local_profile()
	
	# Update stats in victory card
	var total_stars: int = 0
	var stars_dict = SaveManager.user_profile.get("stars", {})
	for k in stars_dict:
		total_stars += int(stars_dict[k])
	if total_stars < 18:
		total_stars = 18 # All 6 worlds conquered!
	stars_label.text = "⭐ %d / 18 Total Stars" % total_stars
	
	var unl_badges: int = BadgeManager.get_unlocked_count()
	var tot_badges: int = BadgeManager.get_total_badges()
	badges_label.text = "🏆 %d / %d Badges Unlocked" % [unl_badges, tot_badges]
	
	if skip_button:
		skip_button.visible = false
	
	_hide_narration()
	
	AudioManager.play_sfx(AudioManager.SFX_BADGE_UNLOCK)
	
	celebration_overlay.visible = true
	celebration_overlay.modulate.a = 0.0
	
	if confetti_particles:
		confetti_particles.restart()
		confetti_particles.emitting = true
	
	celebration_card.scale = Vector2(0.85, 0.85)
	celebration_card.pivot_offset = Vector2(430, 260)
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(celebration_overlay, "modulate:a", 1.0, 0.6)
	tw.tween_property(celebration_card, "scale", Vector2.ONE, 0.65)
	
	epilogue_completed.emit()

func _on_skip_pressed() -> void:
	if _skipped: return
	_skipped = true
	_show_congratulations_screen()
