# res://scripts/ui/CutsceneThrone.gd
extends Control

signal throne_confrontation_completed

@onready var bg_stage_entrance: TextureRect = $Stages/StageEntrance
@onready var bg_stage_prison: TextureRect = $Stages/StagePrison
@onready var bg_stage_meeting: TextureRect = $Stages/StageMeeting

@onready var glitch_particles: CPUParticles2D = $VFX/GlitchParticles
@onready var aura_particles: CPUParticles2D = $VFX/AuraParticles
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

const DIALOG_THRONE_CONFRONTATION: Array = [
	{
		"side": "right",
		"name": "Lord SegFault",
		"left_name": "Adventurer Alex",
		"right_name": "Lord SegFault",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_special.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_segfault.png",
		"show_right": true,
		"mood_tag": "MOCKERY",
		"theme_color": Color("#C084FC"),
		"text": "So... the mortal from UiTM Tapah finally crawls into my sanctum. And look—you brought along my five little fallen puppets! Did you truly believe their restored keystones could undo my absolute corruption?!"
	},
	{
		"side": "left",
		"name": "General Ignis-Py",
		"left_name": "General Ignis-Py",
		"right_name": "Lord SegFault",
		"left_portrait": "res://assets/sprites/portraits/portrait_ignis.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_segfault.png",
		"show_right": true,
		"mood_tag": "WRATH",
		"theme_color": Color("#FB7185"),
		"text": "We are puppets no longer, SegFault! You poisoned our minds with null-pointers and chained us to stone, but Alex shattered your curse! Today, Pythonia's dragon fire answers to him!"
	},
	{
		"side": "left",
		"name": "General NullByte",
		"left_name": "General NullByte",
		"right_name": "Lord SegFault",
		"left_portrait": "res://assets/sprites/portraits/portrait_nullbyte.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_segfault.png",
		"show_right": true,
		"mood_tag": "RESOLVE",
		"theme_color": Color("#F43F5E"),
		"text": "My obsidian blade and syntax shield are pledged to this realm. You will never overwrite Pythonia while we draw breath!"
	},
	{
		"side": "left",
		"name": "General Chronos-If",
		"left_name": "General Chronos-If",
		"right_name": "Lord SegFault",
		"left_portrait": "res://assets/sprites/portraits/portrait_chronos.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_segfault.png",
		"show_right": true,
		"mood_tag": "TEMPORAL",
		"theme_color": Color("#38BDF8"),
		"text": "Your infinite loop of despair shatters here! With Lambda's functions, Vektor's arrays, and my control flow aligned, your execution time has expired!"
	},
	{
		"side": "left",
		"name": "Princess Ada",
		"left_name": "Princess Ada",
		"right_name": "Lord SegFault",
		"left_portrait": "res://assets/sprites/portraits/portrait_princess_ada.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_segfault.png",
		"show_right": true,
		"mood_tag": "WARNING",
		"theme_color": Color("#38BDF8"),
		"text": "Alex! Generals! Beware his core glitch matrix! He has tethered his life force directly to the Citadel's corrupted memory heap—stay together and strike in resonance!"
	},
	{
		"side": "left",
		"name": "Adventurer Alex",
		"left_name": "Adventurer Alex",
		"right_name": "Lord SegFault",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_aggression.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_segfault.png",
		"show_right": true,
		"mood_tag": "DEFIANCE",
		"theme_color": Color("#FCD34D"),
		"text": "You heard them, SegFault. I don't need a weapon in my hands—because every variable, loop, list, and function of Pythonia is flowing right through our fists! Release Princess Ada, or we debug you out of existence!"
	},
	{
		"side": "right",
		"name": "Lord SegFault",
		"left_name": "Adventurer Alex",
		"right_name": "Lord SegFault",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_aggression.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_segfault.png",
		"show_right": true,
		"mood_tag": "FATAL_ERROR",
		"theme_color": Color("#FB7185"),
		"text": "Insolent mortals! Then witness the true catastrophe of a Memory Crash! Let the final compilation commence—NONE SHALL ESCAPE SEGMENTATION FAULT!"
	}
]

func _ready() -> void:
	AudioManager.play_boss_theme(6)
	_setup_visual_elements()
	_start_cutscene()

func _setup_visual_elements() -> void:
	bg_stage_entrance.visible = true
	bg_stage_entrance.modulate.a = 1.0
	bg_stage_entrance.pivot_offset = Vector2(960, 540)
	bg_stage_entrance.scale = Vector2.ONE
	
	bg_stage_prison.visible = true
	bg_stage_prison.modulate.a = 0.0
	bg_stage_prison.pivot_offset = Vector2(960, 540)
	bg_stage_prison.scale = Vector2.ONE
	
	bg_stage_meeting.visible = true
	bg_stage_meeting.modulate.a = 0.0
	bg_stage_meeting.pivot_offset = Vector2(960, 540)
	bg_stage_meeting.scale = Vector2.ONE
	
	flash_rect.visible = false
	flash_rect.modulate.a = 0.0
	narrator_panel.visible = false
	
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)

func _start_cutscene() -> void:
	# =========================================================================
	# SCENE 1: The Citadel Threshold (POV behind Alex & the 5 Generals)
	# =========================================================================
	_show_narration("ACT III • THE OBSIDIAN CITADEL", 
		"Breaching the colossal cathedral gates, Alex and the Five Restored Generals step into the inner sanctum. Far down the hall, Lord SegFault sits upon his throne... waiting in chilling silence.")
	
	var zoom_tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_tw.tween_property(bg_stage_entrance, "scale", Vector2(1.04, 1.04), 4.5)
	
	await get_tree().create_timer(4.5).timeout
	if _skipped: return
	
	# =========================================================================
	# SCENE 2: The Stasis Prism (Upward angle: Princess Ada imprisoned above)
	# =========================================================================
	_shake_screen(4.0, 0.6)
	AudioManager.play_sfx()
	
	if glitch_particles:
		glitch_particles.restart()
		glitch_particles.emitting = true
	
	var tw_prison = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_prison.tween_property(bg_stage_entrance, "modulate:a", 0.0, 0.9)
	tw_prison.tween_property(bg_stage_prison, "modulate:a", 1.0, 0.9)
	
	var prison_zoom = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	prison_zoom.tween_property(bg_stage_prison, "scale", Vector2(1.03, 1.03), 4.0)
	
	_show_narration("THE STASIS PRISM", 
		"Suspended high above the dark throne, Princess Ada remains trapped within crackling stasis crystals, bound by corrupt null-pointer chains...")
	
	await get_tree().create_timer(4.0).timeout
	if _skipped: return
	
	# =========================================================================
	# SCENE 3: The Stand-off Battle (Alex barehanded + 5 Generals ready to fight)
	# =========================================================================
	_hide_narration()
	_shake_screen(8.0, 1.0)
	AudioManager.play_sfx()
	
	# Dramatic screen flash
	var flash_tw = create_tween()
	flash_rect.visible = true
	flash_rect.modulate = Color(1, 1, 1, 0.75)
	flash_tw.tween_property(flash_rect, "modulate:a", 0.0, 0.5)
	
	var tw_meeting = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_meeting.tween_property(bg_stage_prison, "modulate:a", 0.0, 0.7)
	tw_meeting.tween_property(bg_stage_meeting, "modulate:a", 1.0, 0.7)
	
	await get_tree().create_timer(1.2).timeout
	if _skipped: return
	
	# Play enhanced bottom dialogue sequence featuring the Generals, Ada, Alex, and SegFault
	await _play_dialog_and_wait(DIALOG_THRONE_CONFRONTATION)
	if _skipped: return
	
	_finish_and_enter_citadel()

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

func _on_skip_pressed() -> void:
	if _skipped: return
	_skipped = true
	_finish_and_enter_citadel()

func _finish_and_enter_citadel() -> void:
	SaveManager.user_profile["cutscene_segfault_unlocked"] = true
	SaveManager.user_profile["cutscene_segfault_seen"] = true
	SaveManager.user_profile["current_level"] = 6
	SaveManager.save_local_profile()
	
	var fade_tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	flash_rect.modulate = Color(0, 0, 0, 0)
	flash_rect.visible = true
	fade_tw.tween_property(flash_rect, "modulate:a", 1.0, 0.6)
	await fade_tw.finished
	
	throne_confrontation_completed.emit()
	SceneManager.change_scene_with_loading(SceneManager.WORLD_6)
