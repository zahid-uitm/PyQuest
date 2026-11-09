# res://scripts/ui/CutscenePlotTwist.gd
extends Control

signal plot_twist_completed

@onready var bg_stage_volcano: TextureRect = $Stages/StageVolcano
@onready var bg_stage_generals: TextureRect = $Stages/StageGenerals
@onready var bg_stage_keystones: TextureRect = $Stages/StageKeystones
@onready var bg_stage_citadel: TextureRect = $Stages/StageCitadel

@onready var gold_burst_particles: CPUParticles2D = $VFX/GoldBurstParticles
@onready var keystone_particles: CPUParticles2D = $VFX/KeystoneParticles
@onready var bridge_beam: Line2D = $VFX/BridgeBeam
@onready var flash_rect: ColorRect = $VFX/FlashRect

@onready var narrator_panel: PanelContainer = $HUD/NarratorPanel
@onready var narrator_act_label: Label = $HUD/NarratorPanel/Margin/VBox/ActLabel
@onready var narrator_text_label: RichTextLabel = $HUD/NarratorPanel/Margin/VBox/NarrationText

@onready var top_letterbox: ColorRect = $Letterbox/TopBar
@onready var bottom_letterbox: ColorRect = $Letterbox/BottomBar
@onready var skip_button: Button = $HUD/SkipButton
@onready var bottom_dialog_bar: CanvasLayer = $BottomDialogBar

var _skipped: bool = false
var _narrative_tween: Tween = null
var _advance_requested: bool = false

# Part 1: The 5 Bosses Awaken & Thank Alex for Releasing Them from the Curse
const DIALOG_PART_1_AWAKENING: Array = [
	{
		"side": "right",
		"name": "General Ignis-Py",
		"left_name": "Adventurer Alex",
		"right_name": "General Ignis-Py",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_special.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_ignis.png",
		"show_right": true,
		"mood_tag": "AWAKENED",
		"theme_color": Color("#FCD34D"),
		"text": "*Gasp*... The dark fever in my core has finally lifted! Thank you, brave Alex... You have released me from that dreadful curse!"
	},
	{
		"side": "right",
		"name": "General NullByte",
		"left_name": "Adventurer Alex",
		"right_name": "General NullByte",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_special.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_nullbyte.png",
		"show_right": true,
		"mood_tag": "GRATITUDE",
		"theme_color": Color("#10B981"),
		"text": "Not only him, young traveler. All five of us have awakened! Thank you for freeing our souls from the dark corruption that enslaved us."
	},
	{
		"side": "left",
		"name": "Adventurer Alex",
		"left_name": "Adventurer Alex",
		"right_name": "General NullByte",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_special.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_nullbyte.png",
		"show_right": true,
		"mood_tag": "SHOCKED",
		"theme_color": Color("#38BDF8"),
		"text": "Wait... NullByte, Chronos-If, Lambda-Prime, Vektor-Zero, and Ignis-Py?! You're all here—and you're not evil?!"
	},
	{
		"side": "right",
		"name": "General Chronos-If",
		"left_name": "Adventurer Alex",
		"right_name": "General Chronos-If",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_calm.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_chronos.png",
		"show_right": true,
		"mood_tag": "TRUTH",
		"theme_color": Color("#38BDF8"),
		"text": "We were never evil by choice, Alex. We are the [color=#FCD34D][b]Five Elite Generals of Pythonia[/b][/color]—sworn protectors of Princess Ada and guardians of the Five Fundamental Pillars of Python."
	}
]

# Part 2: Flashback — How They Fought Lord SegFault, Were Defeated, and Cursed
const DIALOG_PART_2_THE_TRUTH: Array = [
	{
		"side": "right",
		"name": "General Lambda-Prime",
		"left_name": "Adventurer Alex",
		"right_name": "General Lambda-Prime",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_talk.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_lambda.png",
		"show_right": true,
		"mood_tag": "REVELATION",
		"theme_color": Color("#C084FC"),
		"text": "On the fateful day Pythonia was attacked, the true culprit behind everything—[color=#FB7185][b]Lord SegFault[/b][/color]—descended upon the royal palace!"
	},
	{
		"side": "right",
		"name": "General Vektor-Zero",
		"left_name": "Adventurer Alex",
		"right_name": "General Vektor-Zero",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_talk.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_vektor.png",
		"show_right": true,
		"mood_tag": "SORROW",
		"theme_color": Color("#F59E0B"),
		"text": "All five of us stood together and fought [color=#FB7185][b]Lord SegFault[/b][/color] with all our might to defend Princess Ada... but his dark glitch power was overwhelming. Every single one of us was defeated."
	},
	{
		"side": "right",
		"name": "General Ignis-Py",
		"left_name": "Adventurer Alex",
		"right_name": "General Ignis-Py",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_special.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_ignis.png",
		"show_right": true,
		"mood_tag": "CURSED",
		"theme_color": Color("#FCD34D"),
		"text": "After defeating us, Lord SegFault placed a cruel curse upon all five of us—corrupting our code and puppeteering our bodies to block anyone from reaching the castle!"
	},
	{
		"side": "left",
		"name": "Adventurer Alex",
		"left_name": "Adventurer Alex",
		"right_name": "General Ignis-Py",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_talk.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_ignis.png",
		"show_right": true,
		"mood_tag": "REALIZATION",
		"theme_color": Color("#38BDF8"),
		"text": "So that's why you were guarding each world... You were fighting against his curse the whole time!"
	}
]

# Part 3: Asking Alex for Help to Save Princess Ada and Restore Pythonia
const DIALOG_PART_3_THE_PLEA: Array = [
	{
		"side": "right",
		"name": "General Ignis-Py",
		"left_name": "Adventurer Alex",
		"right_name": "General Ignis-Py",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_calm.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_ignis.png",
		"show_right": true,
		"mood_tag": "PLEA",
		"theme_color": Color("#FCD34D"),
		"text": "Lord SegFault still holds [color=#FCD34D][b]Princess Ada[/b][/color] captive inside the [color=#FB7185][b]Obsidian Castle[/b][/color]. Our strength is spent from breaking the curse... Alex, we need your help!"
	},
	{
		"side": "right",
		"name": "General Chronos-If",
		"left_name": "Adventurer Alex",
		"right_name": "General Chronos-If",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_calm.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_chronos.png",
		"show_right": true,
		"mood_tag": "HOPE",
		"theme_color": Color("#38BDF8"),
		"text": "We have united our five purified keystones to unseal the hidden pathway beyond World 5! The bridge to the Castle now stands open before you."
	},
	{
		"side": "right",
		"name": "General NullByte",
		"left_name": "Adventurer Alex",
		"right_name": "General NullByte",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_smile.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_nullbyte.png",
		"show_right": true,
		"mood_tag": "TRUST",
		"theme_color": Color("#10B981"),
		"text": "Please, Champion Alex—cross the bridge into the Castle, defeat [color=#FB7185][b]Lord SegFault[/b][/color], save [color=#FCD34D][b]Princess Ada[/b][/color], and restore [color=#34D399][b]Pythonia[/b][/color]!"
	},
	{
		"side": "left",
		"name": "Adventurer Alex",
		"left_name": "Adventurer Alex",
		"right_name": "General Ignis-Py",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_aggression.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_ignis.png",
		"show_right": true,
		"mood_tag": "DETERMINED",
		"theme_color": Color("#38BDF8"),
		"text": "Leave it to me, Generals! You protected Pythonia with everything you had—now I'll finish this fight, save Princess Ada, and restore your realm!"
	}
]

func _ready() -> void:
	bg_stage_volcano.modulate.a = 0.0
	bg_stage_generals.modulate.a = 0.0
	bg_stage_keystones.modulate.a = 0.0
	bg_stage_citadel.modulate.a = 0.0
	flash_rect.modulate.a = 0.0
	narrator_panel.visible = false
	
	if bridge_beam:
		bridge_beam.visible = false
	
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	
	_play_timeline()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_skip_pressed()
	elif event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_advance_requested = true

func _wait_for_reading(max_seconds: float) -> void:
	_advance_requested = false
	var elapsed: float = 0.0
	var step: float = 0.1
	while elapsed < max_seconds:
		if _skipped or _advance_requested:
			_advance_requested = false
			break
		await get_tree().create_timer(step).timeout
		elapsed += step

func _play_dialog_and_wait(dialog_lines: Array) -> void:
	if _skipped:
		return
	if bottom_dialog_bar and bottom_dialog_bar.has_method("play_sequence"):
		bottom_dialog_bar.play_sequence(dialog_lines)
		await bottom_dialog_bar.dialog_finished

func _play_timeline() -> void:
	# Letterbox slide in
	top_letterbox.custom_minimum_size.y = 0
	bottom_letterbox.custom_minimum_size.y = 0
	var lb_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	lb_tween.tween_property(top_letterbox, "custom_minimum_size:y", 70.0, 1.0)
	lb_tween.tween_property(bottom_letterbox, "custom_minimum_size:y", 70.0, 1.0)
	
	await get_tree().create_timer(0.3).timeout
	if _skipped: return
	
	# =========================================================================
	# SCENE 1: Defeating Ignis-Py & Shattering the Dark Curse
	# =========================================================================
	await _scene_1_curse_shattered()
	if _skipped: return
	
	# =========================================================================
	# SCENE 2: The 5 Bosses Awaken & Thank Alex for Freeing Them
	# =========================================================================
	await _scene_2_five_generals_awaken()
	if _skipped: return
	
	# =========================================================================
	# SCENE 3: Flashback — Their Battle, Defeat & Curse by Lord SegFault
	# =========================================================================
	await _scene_3_flashback_segfault_battle()
	if _skipped: return
	
	# =========================================================================
	# SCENE 4: The Generals Ask Alex to Save Princess Ada & Unlock the Castle
	# =========================================================================
	await _scene_4_keystone_bridge_plea()
	if _skipped: return
	
	_finish_and_open_map()

# -----------------------------------------------------------------------------
# SCENE 1: Curse Shattered
# -----------------------------------------------------------------------------
func _scene_1_curse_shattered() -> void:
	AudioManager.play_bgm_by_path("res://assets/audio/world5_boss_theme.mp3", 0.01)
	
	bg_stage_volcano.scale = Vector2(1.0, 1.0)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bg_stage_volcano, "modulate:a", 1.0, 1.2)
	tw.tween_property(bg_stage_volcano, "scale", Vector2(1.05, 1.05), 7.5)
	
	_show_narration("ACT II • THE CURSE SHATTERS", 
		"As Alex lands the final blow against Ignis-Py, a blinding surge of golden light erupts across Mount Syntax—shattering the dark magenta strings of corruption across all five realms!")
	
	await _wait_for_reading(7.0)
	if _skipped: return
	
	# Massive golden purification burst
	AudioManager.play_sfx(AudioManager.SFX_BOSS_DEFEAT)
	AudioManager.play_sfx(AudioManager.SFX_SHRINE_AWAKEN)
	_shake_screen(14.0, 1.0)
	
	if gold_burst_particles:
		gold_burst_particles.position = Vector2(960, 540)
		gold_burst_particles.restart()
		gold_burst_particles.emitting = true
	
	flash_rect.modulate = Color(1.0, 0.9, 0.3, 0.0)
	var flash_tw = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	flash_tw.tween_property(flash_rect, "modulate:a", 0.9, 0.3)
	flash_tw.chain().tween_property(flash_rect, "modulate:a", 0.0, 0.7)
	await flash_tw.finished

# -----------------------------------------------------------------------------
# SCENE 2: The 5 Bosses Awaken & Thank Alex
# -----------------------------------------------------------------------------
func _scene_2_five_generals_awaken() -> void:
	AudioManager.play_bgm_by_path("res://assets/audio/mainmenu_music.mp3", 0.01)
	AudioManager.play_sfx(AudioManager.SFX_CHIME)
	
	bg_stage_generals.scale = Vector2(1.0, 1.0)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bg_stage_volcano, "modulate:a", 0.0, 0.9)
	tw.tween_property(bg_stage_generals, "modulate:a", 1.0, 1.2)
	tw.tween_property(bg_stage_generals, "scale", Vector2(1.04, 1.04), 9.0)
	
	_show_narration("THE FIVE GENERALS AWAKEN", 
		"Bathed in golden dawn light, all five bosses—NullByte, Chronos-If, Ignis-Py, Lambda-Prime, and Vektor-Zero—awaken from their dark trance and bow before Alex in gratitude!")
	
	await _wait_for_reading(7.5)
	if _skipped: return
	
	_hide_narration()
	await get_tree().create_timer(0.35).timeout
	if _skipped: return
	
	await _play_dialog_and_wait(DIALOG_PART_1_AWAKENING)

# -----------------------------------------------------------------------------
# SCENE 3: Flashback — Defeated & Cursed by Lord SegFault
# -----------------------------------------------------------------------------
func _scene_3_flashback_segfault_battle() -> void:
	AudioManager.play_bgm_by_path("res://assets/audio/world4_boss_theme.mp3", 0.01)
	AudioManager.play_sfx(AudioManager.SFX_ERROR)
	_shake_screen(10.0, 1.0)
	
	bg_stage_keystones.scale = Vector2(1.0, 1.0)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bg_stage_generals, "modulate:a", 0.0, 0.9)
	tw.tween_property(bg_stage_keystones, "modulate:a", 1.0, 1.2)
	tw.tween_property(bg_stage_keystones, "scale", Vector2(1.05, 1.05), 9.0)
	
	_show_narration("THE TRUTH • DEFEATED & CURSED BY LORD SEGFAULT", 
		"When Lord SegFault attacked Pythonia, the Five Elite Generals fought bravely to stop him—but all five were defeated and bound under a dark curse that forced them to serve as corrupted bosses.")
	
	await _wait_for_reading(8.0)
	if _skipped: return
	
	_hide_narration()
	await get_tree().create_timer(0.35).timeout
	if _skipped: return
	
	await _play_dialog_and_wait(DIALOG_PART_2_THE_TRUTH)

# -----------------------------------------------------------------------------
# SCENE 4: The Plea to Save Princess Ada & The Bridge to the Castle
# -----------------------------------------------------------------------------
func _scene_4_keystone_bridge_plea() -> void:
	AudioManager.play_bgm_by_path("res://assets/audio/mainmenu_music.mp3", 0.01)
	AudioManager.play_sfx(AudioManager.SFX_SPELL_CAST)
	AudioManager.play_bridge_extend()
	
	if keystone_particles:
		keystone_particles.position = Vector2(960, 540)
		keystone_particles.restart()
		keystone_particles.emitting = true
	
	bg_stage_citadel.scale = Vector2(1.0, 1.0)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bg_stage_keystones, "modulate:a", 0.0, 0.9)
	tw.tween_property(bg_stage_citadel, "modulate:a", 1.0, 1.2)
	tw.tween_property(bg_stage_citadel, "scale", Vector2(1.05, 1.05), 9.0)
	
	_show_narration("THE FINAL QUEST • UNSEALING THE CASTLE", 
		"Uniting their five purified keystones in the sky, the Generals forge a radiant bridge across the clouds toward the Obsidian Castle—entrusting Alex to defeat Lord SegFault and save Princess Ada!")
	
	await _wait_for_reading(8.0)
	if _skipped: return
	
	_hide_narration()
	await get_tree().create_timer(0.35).timeout
	if _skipped: return
	
	await _play_dialog_and_wait(DIALOG_PART_3_THE_PLEA)

# -----------------------------------------------------------------------------
# Helpers & Transition
# -----------------------------------------------------------------------------
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
	_narrative_tween.tween_property(narrator_text_label, "visible_ratio", 1.0, 1.2)

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

func _on_skip_pressed() -> void:
	if _skipped: return
	_skipped = true
	_finish_and_open_map()

func _finish_and_open_map() -> void:
	# Set progress flags for World 6 Castle reveal
	SaveManager.user_profile["world5_boss_beaten"] = true
	SaveManager.user_profile["cutscene_ignis_unlocked"] = true
	if int(SaveManager.user_profile.get("unlocked_level", 1)) < 6:
		SaveManager.user_profile["unlocked_level"] = 6
	SaveManager.user_profile["just_unlocked_castle"] = true
	SaveManager.save_local_profile()
	
	# Smooth fade out to black
	var fade_tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	flash_rect.modulate = Color(0, 0, 0, 0)
	flash_rect.visible = true
	fade_tw.tween_property(flash_rect, "modulate:a", 1.0, 0.6)
	await fade_tw.finished
	
	plot_twist_completed.emit()
	SceneManager.change_scene(SceneManager.LEVEL_SELECT)
