# res://scripts/ui/CinematicIntro.gd
extends Control

signal cinematic_completed

@onready var bg_stage_title_long_ago: TextureRect = $Stages/StageTitleLongAgo
@onready var bg_stage_overview: TextureRect = $Stages/StageOverview
@onready var bg_stage_ada: TextureRect = $Stages/StagePrincessAda
@onready var bg_stage_castle: TextureRect = $Stages/StageCastle
@onready var bg_stage_corrupted: TextureRect = $Stages/StageCorrupted
@onready var bg_stage_five_bosses: TextureRect = $Stages/StageFiveBosses
@onready var bg_stage_title_uitm: TextureRect = $Stages/StageTitleUiTM
@onready var bg_stage_bedroom: TextureRect = $Stages/StageBedroom
@onready var bg_stage_vortex: TextureRect = $Stages/StageVortex
@onready var bg_stage_valley: TextureRect = $Stages/StageValley

@onready var matrix_particles: CPUParticles2D = $VFX/MatrixParticles
@onready var portal_burst_particles: CPUParticles2D = $VFX/PortalBurstParticles
@onready var landing_dust_particles: CPUParticles2D = $VFX/LandingDustParticles
@onready var flash_rect: ColorRect = $VFX/FlashRect

@onready var actors_container: Node2D = $Actors
@onready var alex_actor: Sprite2D = $Actors/AlexActor
@onready var pywizard_actor: Sprite2D = $Actors/PyWizardActor

@onready var terminal_window: PanelContainer = $HUD/TerminalWindow
@onready var terminal_code_label: RichTextLabel = $HUD/TerminalWindow/Margin/VBox/CodeText
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

# Master PyWizard never mentions Lord SegFault; the villain is strictly referred to as "????"
const PROLOGUE_DIALOG: Array = [
	{
		"side": "left",
		"name": "Adventurer Alex",
		"left_name": "Adventurer Alex",
		"right_name": "Master PyWizard",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_special.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_pywizard.png",
		"show_right": true,
		"mood_tag": "DAZED",
		"theme_color": Color("#38BDF8"),
		"text": "Ugh... my head... What just happened?! One second I was debugging in my room, and then my screen sucked me in?!"
	},
	{
		"side": "right",
		"name": "Master PyWizard",
		"left_name": "Adventurer Alex",
		"right_name": "Master PyWizard",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_calm.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_pywizard.png",
		"show_right": true,
		"mood_tag": "GREETING",
		"theme_color": Color("#FCD34D"),
		"text": "Welcome, traveler from the mortal realm! You stand upon the sacred soil of [color=#FCD34D][b]Pythonia[/b][/color]—a realm of living code currently drowning in chaos."
	},
	{
		"side": "left",
		"name": "Adventurer Alex",
		"left_name": "Adventurer Alex",
		"right_name": "Master PyWizard",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_talk.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_pywizard.png",
		"show_right": true,
		"mood_tag": "CONFUSED",
		"theme_color": Color("#38BDF8"),
		"text": "Pythonia?! Wait, why does everything look like an epic fantasy RPG? And who are you?"
	},
	{
		"side": "right",
		"name": "Master PyWizard",
		"left_name": "Adventurer Alex",
		"right_name": "Master PyWizard",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_calm.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_pywizard.png",
		"show_right": true,
		"mood_tag": "URGENT",
		"theme_color": Color("#FCD34D"),
		"text": "I am [b]Master PyWizard[/b]. A terrible calamity has struck our kingdom. An unknown dark entity known only as [color=#FB7185][b]????[/b][/color] attacked the palace and abducted our beloved [color=#FCD34D][b]Princess Ada[/b][/color]!"
	},
	{
		"side": "right",
		"name": "Master PyWizard",
		"left_name": "Adventurer Alex",
		"right_name": "Master PyWizard",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_special.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_pywizard.png",
		"show_right": true,
		"mood_tag": "WARNING",
		"theme_color": Color("#FCD34D"),
		"text": "Ever since that day, a dark syntax corruption has infected the Five Great Domains. Five monstrous corrupted bosses now rule each territory with an iron grip, locking all paths to the royal citadel!"
	},
	{
		"side": "left",
		"name": "Adventurer Alex",
		"left_name": "Adventurer Alex",
		"right_name": "Master PyWizard",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_special.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_pywizard.png",
		"show_right": true,
		"mood_tag": "DETERMINED",
		"theme_color": Color("#38BDF8"),
		"text": "Five corrupted bosses?! So to rescue Princess Ada and find a way back home... I have to conquer all five domains?!"
	},
	{
		"side": "right",
		"name": "Master PyWizard",
		"left_name": "Adventurer Alex",
		"right_name": "Master PyWizard",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_aggression.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_pywizard.png",
		"show_right": true,
		"mood_tag": "BLESSING",
		"theme_color": Color("#FCD34D"),
		"text": "Precisely! You must master the [color=#34D399][b]Four Pillars of Python[/b][/color]—Variables, Control Flow, Functions, and Lists. Defeat each corrupted boss, cleanse their corruption, and pave the way to save our Princess!"
	},
	{
		"side": "left",
		"name": "Adventurer Alex",
		"left_name": "Adventurer Alex",
		"right_name": "Master PyWizard",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_smile.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_pywizard.png",
		"show_right": true,
		"mood_tag": "RESOLVED",
		"theme_color": Color("#38BDF8"),
		"text": "Variables, logic loops, functions... Alright, Pythonia—let's debug this world and save Princess Ada!"
	},
	{
		"side": "right",
		"name": "Master PyWizard",
		"left_name": "Adventurer Alex",
		"right_name": "Master PyWizard",
		"left_portrait": "res://assets/sprites/portraits/portrait_alex_smile.png",
		"right_portrait": "res://assets/sprites/portraits/portrait_pywizard.png",
		"show_right": true,
		"mood_tag": "PROPHECY",
		"theme_color": Color("#FCD34D"),
		"text": "Spoken like a true champion. Take this Codex of Variable Valley. Awaken the northern shrines and face the first corrupted warden—[color=#FB7185][b]NullByte[/b][/color]!"
	}
]

func _ready() -> void:
	# Hide all stages initially
	bg_stage_title_long_ago.modulate.a = 0.0
	bg_stage_overview.modulate.a = 0.0
	bg_stage_ada.modulate.a = 0.0
	bg_stage_castle.modulate.a = 0.0
	bg_stage_corrupted.modulate.a = 0.0
	bg_stage_five_bosses.modulate.a = 0.0
	bg_stage_title_uitm.modulate.a = 0.0
	bg_stage_bedroom.modulate.a = 0.0
	bg_stage_vortex.modulate.a = 0.0
	bg_stage_valley.modulate.a = 0.0
	flash_rect.modulate.a = 0.0
	
	terminal_window.visible = false
	narrator_panel.visible = false
	alex_actor.visible = false
	pywizard_actor.visible = false
	
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	
	if bottom_dialog_bar and bottom_dialog_bar.has_signal("dialog_finished"):
		bottom_dialog_bar.dialog_finished.connect(_on_dialog_completed)
	
	# Start cinematic timeline
	_play_cinematic_timeline()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # ESC key
		_on_skip_pressed()
	elif event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		# Space / Enter / Left-click allows reading through scenes faster if desired
		_advance_requested = true

## Allows generous reading time while letting eager players tap Space or Click to continue
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

func _play_cinematic_timeline() -> void:
	# Animate letterbox bars sliding in
	top_letterbox.custom_minimum_size.y = 0
	bottom_letterbox.custom_minimum_size.y = 0
	var lb_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	lb_tween.tween_property(top_letterbox, "custom_minimum_size:y", 70.0, 1.2)
	lb_tween.tween_property(bottom_letterbox, "custom_minimum_size:y", 70.0, 1.2)
	
	await get_tree().create_timer(0.4).timeout
	if _skipped: return
	
	# =========================================================================
	# SCENE 1: Full Page Title Card — "LONG AGO..."
	# =========================================================================
	await _scene_1_title_long_ago()
	if _skipped: return
	
	# =========================================================================
	# SCENE 2: Overview of Peaceful Pythonia
	# =========================================================================
	await _scene_2_pythonia_overview()
	if _skipped: return
	
	# =========================================================================
	# SCENE 3: Princess Ada, Sovereign of the Realm
	# =========================================================================
	await _scene_3_princess_ada()
	if _skipped: return
	
	# =========================================================================
	# SCENE 4: The Abduction by the Unknown Threat (????)
	# =========================================================================
	await _scene_4_the_abduction()
	if _skipped: return
	
	# =========================================================================
	# SCENE 5: The Fall of Pythonia (The Corruption)
	# =========================================================================
	await _scene_5_pythonia_corrupted()
	if _skipped: return
	
	# =========================================================================
	# SCENE 6: The Five Corrupted Bosses Guarding the Pillars
	# =========================================================================
	await _scene_6_five_bosses_commanded()
	if _skipped: return
	
	# =========================================================================
	# SCENE 7: Full Page Title Card — "YEAR 2026 • UiTM TAPAH"
	# =========================================================================
	await _scene_7_title_uitm_tapah()
	if _skipped: return
	
	# =========================================================================
	# SCENE 8: Alex's Bedroom & The Midnight Compilation
	# =========================================================================
	await _scene_8_the_bedroom()
	if _skipped: return
	
	# =========================================================================
	# SCENE 9: The Dimensional Code Vortex
	# =========================================================================
	await _scene_9_the_vortex()
	if _skipped: return
	
	# =========================================================================
	# SCENE 10: Arrival in Variable Valley
	# =========================================================================
	await _scene_10_arrival_in_pythonia()
	if _skipped: return
	
	# =========================================================================
	# SCENE 11: Master PyWizard's Calling & Quest Briefing
	# =========================================================================
	await _scene_11_pywizard_meeting()

# -----------------------------------------------------------------------------
# SCENE 1: Full Page Title Card — "LONG AGO..."
# -----------------------------------------------------------------------------
func _scene_1_title_long_ago() -> void:
	# Atmospheric cosmic celestial opening
	AudioManager.play_bgm_by_path("res://assets/audio/mainmenu_music.mp3", 0.01)
	
	bg_stage_title_long_ago.scale = Vector2(1.0, 1.0)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bg_stage_title_long_ago, "modulate:a", 1.0, 1.8)
	tw.tween_property(bg_stage_title_long_ago, "scale", Vector2(1.04, 1.04), 7.5)
	
	_show_narration("THE ANCIENT CHRONICLES OF PYTHONIA", 
		"Before the mortal realms were cataloged... in a time when pure code and cosmic magic were one and the same...")
	
	# Generous reading duration (7.5s or click to advance)
	await _wait_for_reading(7.5)
	if _skipped: return

# -----------------------------------------------------------------------------
# SCENE 2: Overview of Peaceful Pythonia
# -----------------------------------------------------------------------------
func _scene_2_pythonia_overview() -> void:
	# Transition to radiant peaceful kingdom overview
	bg_stage_overview.scale = Vector2(1.0, 1.0)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bg_stage_title_long_ago, "modulate:a", 0.0, 1.2)
	tw.tween_property(bg_stage_overview, "modulate:a", 1.0, 1.4)
	tw.tween_property(bg_stage_overview, "scale", Vector2(1.05, 1.05), 8.5)
	
	_show_narration("PROLOGUE • THE GOLDEN REALM OF PYTHONIA", 
		"Pythonia was once a realm of boundless beauty, safe and prosperous... where living streams of syntax nourished lush floating isles, glowing rivers, and peaceful ancient shrines.")
	
	# Generous reading duration (8.5s or click to advance)
	await _wait_for_reading(8.5)
	if _skipped: return

# -----------------------------------------------------------------------------
# SCENE 3: Princess Ada, Sovereign of the Realm
# -----------------------------------------------------------------------------
func _scene_3_princess_ada() -> void:
	# Crossfade into Princess Ada on her sunlit palace balcony
	bg_stage_ada.scale = Vector2(1.0, 1.0)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bg_stage_overview, "modulate:a", 0.0, 1.2)
	tw.tween_property(bg_stage_ada, "modulate:a", 1.0, 1.2)
	tw.tween_property(bg_stage_ada, "scale", Vector2(1.05, 1.05), 8.5)
	
	_show_narration("PROLOGUE • PRINCESS ADA", 
		"At the heart of the kingdom ruled [color=#FCD34D][b]Princess Ada[/b][/color]—a beloved, gentle sovereign whose royal compiler magic kept the elements in harmonious, sacred balance.")
	
	# Generous reading duration (8.5s or click to advance)
	await _wait_for_reading(8.5)
	if _skipped: return

# -----------------------------------------------------------------------------
# SCENE 4: The Abduction by the Unknown Threat (????)
# -----------------------------------------------------------------------------
func _scene_4_the_abduction() -> void:
	# Sudden ominous musical cut to dark battle theme
	AudioManager.play_bgm_by_path("res://assets/audio/world4_boss_theme.mp3", 0.01)
	
	# Transition to throne room invasion
	bg_stage_castle.scale = Vector2(1.0, 1.0)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bg_stage_ada, "modulate:a", 0.0, 0.6)
	tw.tween_property(bg_stage_castle, "modulate:a", 1.0, 0.8)
	tw.tween_property(bg_stage_castle, "scale", Vector2(1.06, 1.06), 9.0)
	
	# Violent glitch attack effects: hit SFX, error SFX, heavy shake
	AudioManager.play_sfx(AudioManager.SFX_BOSS_HIT)
	AudioManager.play_sfx(AudioManager.SFX_ERROR)
	_shake_screen(16.0, 1.6)
	
	# Ominous purple static flash
	flash_rect.modulate = Color(0.7, 0.1, 0.9, 0.0)
	var flash_tw = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	flash_tw.tween_property(flash_rect, "modulate:a", 0.7, 0.25)
	flash_tw.chain().tween_property(flash_rect, "modulate:a", 0.0, 0.45)
	
	_show_narration("PROLOGUE • THE UNKNOWN INTRUDER", 
		"Until one fateful day, a shadowy, malevolent anomaly known only as [color=#FB7185][b]????[/b][/color] shattered the palace seals! Wrapped in dark glitch tendrils, the intruder captured Princess Ada and vanished into the abyss!")
	
	# Generous reading duration (8.8s or click to advance)
	await _wait_for_reading(8.8)
	if _skipped: return

# -----------------------------------------------------------------------------
# SCENE 5: The Fall of Pythonia (The Corruption)
# -----------------------------------------------------------------------------
func _scene_5_pythonia_corrupted() -> void:
	# Crossfade from castle throne room into corrupted wasteland
	bg_stage_corrupted.scale = Vector2(1.0, 1.0)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bg_stage_castle, "modulate:a", 0.0, 1.0)
	tw.tween_property(bg_stage_corrupted, "modulate:a", 1.0, 1.4)
	tw.tween_property(bg_stage_corrupted, "scale", Vector2(1.05, 1.05), 9.0)
	
	# Error glitch rumble and screen tremor
	AudioManager.play_sfx(AudioManager.SFX_ERROR)
	_shake_screen(8.0, 1.2)
	
	_show_narration("PROLOGUE • THE CORRUPTED REALM", 
		"With Princess Ada stolen into the shadows, a dark syntax blight devoured the kingdom. Pure rivers of code twisted into toxic glitch streams, ancient monoliths fractured under memory leaks, and the once-peaceful realm of Pythonia fell into darkness.")
	
	# Generous reading duration (8.8s or click to advance)
	await _wait_for_reading(8.8)
	if _skipped: return

# -----------------------------------------------------------------------------
# SCENE 6: The Five Corrupted Bosses Commanded by ????
# -----------------------------------------------------------------------------
func _scene_6_five_bosses_commanded() -> void:
	# Crossfade from corrupted realm into the 5 bosses guarding the 5 pillars under ????
	bg_stage_five_bosses.scale = Vector2(1.0, 1.0)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bg_stage_corrupted, "modulate:a", 0.0, 1.0)
	tw.tween_property(bg_stage_five_bosses, "modulate:a", 1.0, 1.4)
	tw.tween_property(bg_stage_five_bosses, "scale", Vector2(1.06, 1.06), 9.5)
	
	# Menacing boss tremor & glitch impact
	AudioManager.play_sfx(AudioManager.SFX_BOSS_HIT)
	AudioManager.play_sfx(AudioManager.SFX_ERROR)
	_shake_screen(11.0, 1.4)
	
	_show_narration("PROLOGUE • THE FIVE CORRUPTED WARDENS", 
		"To seal the kingdom's fate, [color=#FB7185][b]????[/b][/color] stationed five terrifying, corrupted bosses across the land—[color=#F43F5E][b]NullByte[/b][/color], [color=#38BDF8][b]Chronos-If[/b][/color], [color=#C084FC][b]Lambda-Prime[/b][/color], [color=#F59E0B][b]Vektor-Zero[/b][/color], and [color=#FB7185][b]Ignis-Py[/b][/color]—commanding them to ruthlessly guard each of the Five Pillars of Pythonia!")
	
	# Generous reading duration (9.2s or click to advance)
	await _wait_for_reading(9.2)
	if _skipped: return
	
	# Fade out to dark silence before cutting to modern day
	var fade_tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fade_tw.tween_property(bg_stage_five_bosses, "modulate:a", 0.0, 1.0)
	fade_tw.parallel().tween_property(narrator_panel, "modulate:a", 0.0, 0.6)
	await fade_tw.finished
	narrator_panel.visible = false
	
	await get_tree().create_timer(0.6).timeout

# -----------------------------------------------------------------------------
# SCENE 7: Full Page Title Card — "YEAR 2026 • UiTM TAPAH"
# -----------------------------------------------------------------------------
func _scene_7_title_uitm_tapah() -> void:
	# Quiet, atmospheric night campus music
	AudioManager.play_bgm_by_path("res://assets/audio/world1_music.mp3", 0.01)
	
	bg_stage_title_uitm.scale = Vector2(1.0, 1.0)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bg_stage_title_uitm, "modulate:a", 1.0, 1.6)
	tw.tween_property(bg_stage_title_uitm, "scale", Vector2(1.04, 1.04), 7.5)
	
	_show_narration("ACT I • YEAR 2026 • UiTM TAPAH", 
		"In the mortal realm, at the quiet campus of [color=#38BDF8][b]UiTM Tapah[/b][/color]... Midnight winds blow through the hills as one lone student stays awake in his room, debugging into the late hours.")
	
	# Generous reading duration (7.5s or click to advance)
	await _wait_for_reading(7.5)
	if _skipped: return

# -----------------------------------------------------------------------------
# SCENE 8: Alex's Bedroom & The Midnight Compilation
# -----------------------------------------------------------------------------
func _scene_8_the_bedroom() -> void:
	# Transition into bedroom interior
	bg_stage_bedroom.scale = Vector2(1.0, 1.0)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bg_stage_title_uitm, "modulate:a", 0.0, 1.0)
	tw.tween_property(bg_stage_bedroom, "modulate:a", 1.0, 1.4)
	tw.tween_property(bg_stage_bedroom, "scale", Vector2(1.06, 1.06), 8.0)
	
	_show_narration("THE MIDNIGHT COMPILATION", 
		"Alex was debugging an ancient, undocumented Python script discovered deep in a forgotten code archive...")
	
	await get_tree().create_timer(2.6).timeout
	if _skipped: return
	
	# Show terminal window with live typing effect
	terminal_window.visible = true
	terminal_window.modulate.a = 0.0
	var tw_term = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_term.tween_property(terminal_window, "modulate:a", 1.0, 0.4)
	
	var terminal_lines = [
		">> import sys, time, universe",
		">> realm = universe.connect('pythonia')",
		">> realm.compile(bypass_reality_guards=True)",
		">> [!] WARNING: Dimensional stack overflow detected!",
		">> [!] RUNTIME ERROR: User being pulled into memory stream...!"
	]
	
	terminal_code_label.text = ""
	for line in terminal_lines:
		if _skipped: return
		terminal_code_label.text += line + "\n"
		AudioManager.play_npc_chat()
		await get_tree().create_timer(0.48).timeout
	
	# Audio buildup: hum turns into alarming frequency
	AudioManager.play_sfx(AudioManager.SFX_SHRINE_AWAKEN)
	
	# Monitor starts pulsating violently with camera shake
	_shake_screen(12.0, 1.6)
	
	await get_tree().create_timer(1.2).timeout
	if _skipped: return
	
	# Blinding portal surge flash
	AudioManager.play_sfx(AudioManager.SFX_SPELL_CAST)
	flash_rect.modulate = Color(0.2, 0.9, 1.0, 0.0)
	var flash_tw = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	flash_tw.tween_property(flash_rect, "modulate:a", 1.0, 0.3)
	await flash_tw.finished

# -----------------------------------------------------------------------------
# SCENE 9: Dimensional Vortex
# -----------------------------------------------------------------------------
func _scene_9_the_vortex() -> void:
	# Hide bedroom and terminal
	bg_stage_bedroom.modulate.a = 0.0
	terminal_window.visible = false
	
	# Switch BGM to mystical energetic theme
	AudioManager.play_bgm_by_path("res://assets/audio/world1_music.mp3", 0.01)
	AudioManager.play_sfx(AudioManager.SFX_TELEPORT)
	
	# Show vortex background
	bg_stage_vortex.modulate.a = 1.0
	bg_stage_vortex.scale = Vector2(1.15, 1.15)
	
	# Fade down white flash to reveal vortex
	var flash_tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	flash_tw.tween_property(flash_rect, "modulate:a", 0.0, 0.8)
	
	# Turn on matrix particles and portal particles
	matrix_particles.emitting = true
	portal_burst_particles.emitting = true
	
	_show_narration("ACT II • THE DIGITAL CHASM", 
		"Physical reality dissolves into infinite streams of syntax! Alex is pulled across the dimensional continuum where living code shapes reality itself.")
	
	# Vortex dynamic camera rotation and zoom pulse
	var vortex_tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	vortex_tw.tween_property(bg_stage_vortex, "scale", Vector2(1.0, 1.0), 5.5)
	vortex_tw.tween_property(bg_stage_vortex, "rotation", 0.04, 2.75)
	vortex_tw.chain().tween_property(bg_stage_vortex, "rotation", -0.04, 2.75)
	
	_shake_screen(6.0, 4.0)
	
	# Generous vortex reading time
	await _wait_for_reading(6.5)
	if _skipped: return
	
	# Sudden dimensional burst before landing
	AudioManager.play_sfx(AudioManager.SFX_SPELL_CAST)
	flash_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var flash_tw2 = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	flash_tw2.tween_property(flash_rect, "modulate:a", 1.0, 0.35)
	await flash_tw2.finished

# -----------------------------------------------------------------------------
# SCENE 10: Arrival in Variable Valley
# -----------------------------------------------------------------------------
func _scene_10_arrival_in_pythonia() -> void:
	# Hide vortex and turn off matrix storm
	bg_stage_vortex.modulate.a = 0.0
	matrix_particles.emitting = false
	portal_burst_particles.emitting = false
	
	# Reveal Variable Valley background
	bg_stage_valley.modulate.a = 1.0
	bg_stage_valley.scale = Vector2(1.0, 1.0)
	
	var flash_tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	flash_tw.tween_property(flash_rect, "modulate:a", 0.0, 0.6)
	
	_show_narration("ACT III • DESCENT INTO VARIABLE VALLEY", 
		"Breaking through the cloud layer of Pythonia, the mortal coder crashes down onto the fertile meadows of Variable Valley!")
	
	# Animate Alex falling from top of screen onto the grass
	actors_container.visible = true
	alex_actor.visible = true
	alex_actor.frame = 48 # Hurt/fall frame
	alex_actor.position = Vector2(960, -120)
	alex_actor.scale = Vector2(4.5, 4.5)
	alex_actor.rotation = -0.4
	
	var drop_tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop_tw.tween_property(alex_actor, "position:y", 680.0, 0.9)
	drop_tw.parallel().tween_property(alex_actor, "rotation", 0.0, 0.9)
	await drop_tw.finished
	
	# Impact landing: dust burst, thud SFX, heavy shake
	landing_dust_particles.position = alex_actor.position + Vector2(0, 30)
	landing_dust_particles.restart()
	landing_dust_particles.emitting = true
	AudioManager.play_sfx(AudioManager.SFX_PLAYER_HURT)
	_shake_screen(18.0, 0.6)
	
	# Alex lies on ground, dazed
	alex_actor.frame = 54 # Prone / ground
	await get_tree().create_timer(1.2).timeout
	if _skipped: return
	
	# Alex recovers, stands up
	alex_actor.frame = 48 # Dazed kneel
	await get_tree().create_timer(0.6).timeout
	if _skipped: return
	
	alex_actor.frame = 0 # Stance idle down
	alex_actor.scale = Vector2(4.2, 4.2)
	
	# Shake off dust animation
	var shake_tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shake_tw.tween_property(alex_actor, "position:x", 955.0, 0.08)
	shake_tw.tween_property(alex_actor, "position:x", 965.0, 0.08)
	shake_tw.tween_property(alex_actor, "position:x", 960.0, 0.08)
	
	await get_tree().create_timer(1.2).timeout

# -----------------------------------------------------------------------------
# SCENE 11: Master PyWizard's Calling & Dialog (Spoiler-free!)
# -----------------------------------------------------------------------------
func _scene_11_pywizard_meeting() -> void:
	# Hide narration box for the interactive dialogue
	_hide_narration()
	
	# PyWizard teleport flash and entrance
	pywizard_actor.visible = true
	pywizard_actor.position = Vector2(1160, 670)
	pywizard_actor.scale = Vector2(0.1, 4.2)
	pywizard_actor.modulate.a = 0.0
	
	AudioManager.play_sfx(AudioManager.SFX_TELEPORT)
	portal_burst_particles.position = pywizard_actor.position
	portal_burst_particles.restart()
	portal_burst_particles.emitting = true
	
	var wiz_tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	wiz_tw.tween_property(pywizard_actor, "scale", Vector2(4.2, 4.2), 0.5)
	wiz_tw.parallel().tween_property(pywizard_actor, "modulate:a", 1.0, 0.4)
	
	await wiz_tw.finished
	AudioManager.play_sfx(AudioManager.SFX_CHIME)
	
	# Idle hover bob for PyWizard
	var bob_tw = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob_tw.tween_property(pywizard_actor, "position:y", 662.0, 1.4)
	bob_tw.tween_property(pywizard_actor, "position:y", 670.0, 1.4)
	
	await get_tree().create_timer(0.6).timeout
	if _skipped: return
	
	# Trigger BottomDialogBar sequence with Master PyWizard and Alex
	if bottom_dialog_bar and bottom_dialog_bar.has_method("play_sequence"):
		bottom_dialog_bar.play_sequence(PROLOGUE_DIALOG)
	else:
		_finish_and_enter_game()

func _on_dialog_completed() -> void:
	if _skipped: return
	_finish_and_enter_game()

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
		tw.tween_property(narrator_panel, "modulate:a", 0.0, 0.35)
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
	_finish_and_enter_game()

func _finish_and_enter_game() -> void:
	# Save intro_watched status so it doesn't force rewatch
	SaveManager.user_profile["intro_watched"] = true
	SaveManager.save_local_profile()
	
	# Unlock "First Steps" badge if not unlocked
	if Engine.has_singleton("BadgeManager") or get_node_or_null("/root/BadgeManager"):
		var bm = get_node("/root/BadgeManager")
		if bm and bm.has_method("unlock_badge"):
			bm.unlock_badge("first_steps")
	
	# Smooth fade out to black
	var fade_tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	flash_rect.modulate = Color(0, 0, 0, 0)
	flash_rect.visible = true
	fade_tw.tween_property(flash_rect, "modulate:a", 1.0, 0.6)
	await fade_tw.finished
	
	# Transition into World 1
	cinematic_completed.emit()
	SceneManager.change_scene_with_loading(SceneManager.WORLD_1)
