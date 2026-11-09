# res://scripts/world/VisualStage.gd
extends Node2D

@onready var alex: CharacterBody2D = $Alex
@onready var chest: Sprite2D = $TreasureChest/Sprite2D
@onready var chest_particles: CPUParticles2D = $TreasureChest/ChestParticles
@onready var pywizard: Node2D = $PyWizard
@onready var pywizard_sprite: Sprite2D = $PyWizard/Sprite2D
@onready var float_label: Label = $FloatingLabel

var alex_start_pos: Vector2 = Vector2(280, 725)
var boss_start_pos: Vector2 = Vector2(720, 725)
var wizard_base_y: float = 515.0
var boss_max_hp: int = 500
var boss_hp: int = 500
var hero_hp: int = 100
var boss_anim_state: String = "idle" # "idle", "walk", "attack", "hurt", "dead"
var idle_timer: float = 0.0

func _ready() -> void:
	reset_stage()

func _process(delta: float) -> void:
	idle_timer += delta
	if pywizard_sprite and pywizard_sprite.hframes >= 6:
		pywizard_sprite.frame = int(idle_timer * 5.0) % 6
	if pywizard:
		pywizard.position.y = wizard_base_y + sin(idle_timer * 2.5) * 6.0
		
	var b_left = get_node_or_null("DungeonEnvironment/BrazierLeft") as Sprite2D
	var b_right = get_node_or_null("DungeonEnvironment/BrazierRight") as Sprite2D
	if b_left and b_left.hframes >= 4:
		b_left.frame = int(idle_timer * 7.0) % 4
	if b_right and b_right.hframes >= 4:
		b_right.frame = (int(idle_timer * 7.0) + 2) % 4
		
	var boss_sprite = get_node_or_null("BossGolem/BossSprite") as Sprite2D
	if boss_sprite and boss_sprite.hframes >= 6 and boss_sprite.vframes >= 10:
		if boss_anim_state == "idle":
			# Row 1: side_idle (frames 6..11)
			boss_sprite.frame = 6 + (int(idle_timer * 5.0) % 6)
		elif boss_anim_state == "walk":
			# Row 4: side_walk (frames 24..29)
			boss_sprite.frame = 24 + (int(idle_timer * 8.0) % 6)

func _trigger_screen_flash(flash_col: Color) -> void:
	if not bool(SaveManager.get_setting("screen_flash", true)):
		return
	var flash = get_node_or_null("ScreenFlash") as ColorRect
	if not flash:
		return
	flash.visible = true
	flash.color = flash_col
	var tw = create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.28)
	tw.tween_callback(func(): flash.visible = false)

func _shake_arena(intensity: float = 10.0) -> void:
	if not bool(SaveManager.get_setting("screen_shake", true)):
		return
	var env = get_node_or_null("DungeonEnvironment") as Node2D
	if not env:
		return
	var stw = create_tween()
	stw.tween_property(env, "position", Vector2(intensity, -intensity * 0.6), 0.04)
	stw.tween_property(env, "position", Vector2(-intensity, intensity * 0.6), 0.04)
	stw.tween_property(env, "position", Vector2(intensity * 0.5, 0), 0.04)
	stw.tween_property(env, "position", Vector2.ZERO, 0.05)

func _update_arena_bars() -> void:
	var cur_lvl = int(SaveManager.user_profile.get("current_level", 1))
	var b_name = "Lord SegFault" if cur_lvl == 6 else ("Ignis-Py" if cur_lvl == 5 else ("Vektor-Zero" if cur_lvl == 4 else ("Lambda-Prime" if cur_lvl == 3 else ("Chronos-If" if cur_lvl == 2 else "NullByte"))))
	var hp_label = get_node_or_null("DungeonEnvironment/BossHUD/VBox/HeaderHBox/BossHPLabel") as Label
	var hp_bar = get_node_or_null("DungeonEnvironment/BossHUD/VBox/BossHPBar") as ProgressBar
	var status_lbl = get_node_or_null("DungeonEnvironment/BossHUD/VBox/BossStatusLabel") as Label
	if hp_label:
		hp_label.text = "%d / %d HP" % [max(0, boss_hp), boss_max_hp]
	if hp_bar:
		hp_bar.max_value = float(boss_max_hp)
		var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(hp_bar, "value", float(max(0, boss_hp)), 0.35)
	if status_lbl:
		if hero_hp <= 0:
			status_lbl.text = "💀 ADVENTURER FALLEN! %s's Curse shattered Alex's shield!" % b_name
		elif boss_hp <= 0:
			status_lbl.text = "🏆 BOSS DEFEATED! %s has fallen and Princess Ada is freed!" % b_name if cur_lvl == 6 else "🏆 BOSS DEFEATED! %s has fallen and the Grand Relic Chest is unsealed!" % b_name
		elif cur_lvl == 6:
			if boss_hp <= 150:
				status_lbl.text = "👑 FINAL PHASE [SOURCE CODE RESONANCE]: Unleash the 5 Generals' power to shatter Princess Ada's Prism!"
			elif boss_hp <= 400:
				status_lbl.text = "⚡ PHASE II [KERNEL CORRUPTION]: SegFault is scrambling memory! Use your General Assist Skills!"
			else:
				status_lbl.text = "🏰 PHASE I [THE NULL SOVEREIGN]: All 5 Awakened Generals stand with you! Strike Lord SegFault!"
		elif cur_lvl == 5:
			if boss_hp <= 100:
				status_lbl.text = "👑 STAGE III [GRAND SYNTHESIS]: All 4 Mentors lend their power! Unleash the Final Combo!"
			elif boss_hp <= 400:
				status_lbl.text = "🔥 STAGE II [OVERDRIVE & CORRUPTION]: Ignis-Py is corrupting Python code! Debug & Strike!"
			else:
				status_lbl.text = "🌋 STAGE I [THE OBSIDIAN SHIELD]: Shatter Ignis-Py's volcanic armor with synthesis spells!"
		elif boss_hp <= 100:
			status_lbl.text = "🔥 FINAL PHASE: %s is down to 100 HP! Unleash the Final Spell Combo!" % b_name
		else:
			status_lbl.text = "⚡ SANCTUM SEAL ACTIVE: Execute valid Python spells to shatter %s's armor!" % b_name

	var hero_lbl = get_node_or_null("HeroHUDPanel/HeroHUD/HeroNameLabel") as Label
	var hero_bar = get_node_or_null("HeroHUDPanel/HeroHUD/HeroHPBar") as ProgressBar
	if hero_lbl:
		if hero_hp <= 0:
			hero_lbl.text = "💀 Adventurer Alex • 0/100 HP (DEFEATED)"
		else:
			hero_lbl.text = "🛡️ Adventurer Alex • %d/100 HP" % max(0, hero_hp)
	if hero_bar:
		hero_bar.value = float(max(0, hero_hp))

func is_hero_dead() -> bool:
	return hero_hp <= 0

# Live Boss Battle animation when player submits correct Python code
func play_correct_action(action_type: String, score_val: int, xp_val: int) -> void:
	var boss_node = get_node_or_null("BossGolem") as Node2D
	var boss_sprite = get_node_or_null("BossGolem/BossSprite") as Sprite2D
	var hit_particles = get_node_or_null("BossGolem/HitParticles") as CPUParticles2D
	var spell_proj = get_node_or_null("SpellProjectile") as Sprite2D
	var chest_label = get_node_or_null("TreasureChest/ChestLabel") as Label

	# 1. Alex steps forward on the runic stage and casts a Python spell
	if alex:
		alex.play_anim("side_walk")
		var walk_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		walk_tween.tween_property(alex, "position:x", alex_start_pos.x + 120.0, 0.35)
		await walk_tween.finished
		alex.play_anim("side_attack")

	# 2. Launch Arcane Python Fireball Projectile toward NullByte
	if spell_proj:
		AudioManager.play_spell_cast()
		spell_proj.position = Vector2(alex_start_pos.x + 160.0, alex_start_pos.y + 15.0)
		spell_proj.visible = true
		spell_proj.scale = Vector2(1.4, 1.4)
		var proj_tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		proj_tw.tween_property(spell_proj, "position", Vector2(boss_start_pos.x - 15.0, boss_start_pos.y + 15.0), 0.32)
		proj_tw.parallel().tween_property(spell_proj, "scale", Vector2(2.8, 2.8), 0.32)
		await proj_tw.finished
		spell_proj.visible = false

	# 3. Impact on Boss! (-100 HP)
	AudioManager.play_boss_hit()
	boss_hp = max(0, boss_hp - 100)
	_update_arena_bars()
	_trigger_screen_flash(Color(0.35, 0.9, 1.0, 0.32))
	_shake_arena(12.0)

	if hit_particles:
		hit_particles.restart()
		hit_particles.emitting = true

	if boss_sprite and boss_node:
		boss_anim_state = "hurt"
		boss_sprite.frame = 54 # First recoil frame of row 9
		boss_sprite.modulate = Color(2.4, 0.6, 0.9, 1.0)
		var hit_tw = create_tween()
		hit_tw.tween_property(boss_node, "position:x", boss_start_pos.x + 30.0, 0.07)
		hit_tw.tween_property(boss_node, "position:x", boss_start_pos.x - 18.0, 0.07)
		hit_tw.tween_property(boss_node, "position:x", boss_start_pos.x, 0.08)
		await hit_tw.finished
		boss_sprite.modulate = Color.WHITE

	show_floating_text("💥 -100 BOSS HP!  (+%d Score  +%d XP)" % [score_val, xp_val], Color("#FBBF24"))

	# 4. If Boss is defeated (0 HP) or final finisher triggered, play 3-frame death animation & open Relic Chest!
	if boss_hp <= 0 or action_type == "boss_finisher":
		boss_hp = 0
		_update_arena_bars()
		boss_anim_state = "dead"
		AudioManager.play_boss_defeat()
		if boss_sprite:
			boss_sprite.frame = 54
			await get_tree().create_timer(0.18).timeout
			boss_sprite.frame = 55
			await get_tree().create_timer(0.18).timeout
			boss_sprite.frame = 56
		if chest:
			AudioManager.play_chest_open()
			chest.frame = 1
			await get_tree().create_timer(0.12).timeout
			chest.frame = 2
			await get_tree().create_timer(0.12).timeout
			chest.frame = 3
		if chest_label:
			chest_label.text = "✨ Relic Chest Unlocked!"
		if chest_particles:
			chest_particles.restart()
			chest_particles.emitting = true
	else:
		boss_anim_state = "idle"
		await get_tree().create_timer(0.35).timeout

	# 5. Alex returns to his runic battle platform
	if alex:
		alex.play_anim("side_walk")
		alex.face_direction(true)
		var return_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		return_tween.tween_property(alex, "position:x", alex_start_pos.x, 0.35)
		await return_tween.finished
		alex.face_direction(false)
		alex.play_anim("side_idle")

# Live Boss Counterattack when code has a Syntax Error (Walks & Slashes with Corrupt Syntax Blade!)
func play_incorrect_action(shielded: bool = false) -> void:
	var boss_node = get_node_or_null("BossGolem") as Node2D
	var boss_sprite = get_node_or_null("BossGolem/BossSprite") as Sprite2D

	if boss_sprite and boss_node:
		# 1. Boss walks left across the runic bridge toward Alex
		boss_sprite.flip_h = true
		boss_anim_state = "walk"
		var lunge_tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		lunge_tw.tween_property(boss_node, "position:x", alex_start_pos.x + 105.0, 0.45)
		await lunge_tw.finished
		
		# 2. Boss swings Corrupt Syntax Blade (Row 7: side_attack frames 42..45)
		boss_anim_state = "attack"
		if shielded:
			AudioManager.play_sfx()
			_trigger_screen_flash(Color(0.2, 0.85, 1.0, 0.4))
			_shake_arena(8.0)
		else:
			AudioManager.play_player_hurt()
			_trigger_screen_flash(Color(1.0, 0.15, 0.35, 0.38))
			_shake_arena(15.0)
		for atk_f in [42, 43, 44, 45]:
			boss_sprite.frame = atk_f
			await get_tree().create_timer(0.08).timeout

	if shielded:
		show_floating_text("🛡️ CHRONOS TEMPORAL SHIELD! (0 Damage Taken!)", Color("#38BDF8"))
	else:
		hero_hp = max(0, hero_hp - 35)
		_update_arena_bars()

		if hero_hp <= 0:
			show_floating_text("💀 ALEX DEFEATED! (0 / 100 HP)", Color("#EF4444"))
			if alex and alex.has_method("perform_death"):
				await alex.perform_death()
		else:
			# Alex recoils
			if alex and alex.has_method("perform_recoil"):
				alex.perform_recoil()
			show_floating_text("⚡ BOSS SLASH! -35 Shield HP (%d/100 HP)" % hero_hp, Color("#EF4444"))

	# 3. Boss walks back to his platform
	if boss_sprite and boss_node:
		boss_sprite.flip_h = false
		boss_anim_state = "walk"
		var back_tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		back_tw.tween_property(boss_node, "position:x", boss_start_pos.x, 0.45)
		await back_tw.finished
		boss_sprite.flip_h = true
		boss_anim_state = "idle"

func play_general_assist_effect(msg: String, color: Color, heal_hero: int = 0, boss_dmg: int = 0) -> void:
	AudioManager.play_spell_cast()
	_trigger_screen_flash(Color(color.r, color.g, color.b, 0.35))
	_shake_arena(10.0)
	if heal_hero > 0:
		hero_hp = min(100, hero_hp + heal_hero)
	if boss_dmg > 0:
		boss_hp = max(20, boss_hp - boss_dmg)
		var hit_particles = get_node_or_null("BossGolem/HitParticles") as CPUParticles2D
		if hit_particles:
			hit_particles.restart()
			hit_particles.emitting = true
	if heal_hero > 0 or boss_dmg > 0:
		_update_arena_bars()
	show_floating_text(msg, color)

func show_pywizard_hint() -> void:
	AudioManager.play_sfx("res://assets/audio/sfx_chime.wav")
	if pywizard:
		var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_property(pywizard, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(pywizard, "scale", Vector2(1.0, 1.0), 0.3)
	show_floating_text("🧙 PyWizard: Spell Formula Revealed!", Color("#60A5FA"))

func show_floating_text(msg: String, color: Color) -> void:
	if not float_label:
		return
	float_label.text = msg
	float_label.visible = true
	float_label.position = Vector2(310, 560)
	float_label.modulate = color
	float_label.modulate.a = 1.0

	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(float_label, "position:y", 480.0, 1.2)
	tween.parallel().tween_property(float_label, "modulate:a", 0.0, 1.2)
	await tween.finished
	float_label.visible = false

func reset_stage() -> void:
	var cur_lvl = int(SaveManager.user_profile.get("current_level", 1))
	boss_max_hp = 600 if cur_lvl >= 5 else 500
	boss_hp = boss_max_hp
	hero_hp = 100
	boss_anim_state = "idle"
	_update_arena_bars()

	var boss_node = get_node_or_null("BossGolem") as Node2D
	var boss_sprite = get_node_or_null("BossGolem/BossSprite") as Sprite2D
	var boss_tag = get_node_or_null("BossGolem/BossTag") as Label
	var boss_title = get_node_or_null("DungeonEnvironment/BossHUD/VBox/HeaderHBox/BossTitleLabel") as Label
	var arena_wallpaper = get_node_or_null("DungeonEnvironment/ArenaWallpaper") as TextureRect
	var vortex_particles = get_node_or_null("DungeonEnvironment/VortexParticles") as CPUParticles2D
	var stage_embers = get_node_or_null("DungeonEnvironment/StageEmbers") as CPUParticles2D
	var brazier_left = get_node_or_null("DungeonEnvironment/BrazierLeft") as Sprite2D
	var brazier_right = get_node_or_null("DungeonEnvironment/BrazierRight") as Sprite2D
	var boss_hud = get_node_or_null("DungeonEnvironment/BossHUD") as PanelContainer

	# 1. Dynamically apply world-specific boss arena background wallpaper
	var bg_path = "res://assets/maps/boss_arena_world%d.jpg" % cur_lvl
	if arena_wallpaper:
		if FileAccess.file_exists(bg_path):
			arena_wallpaper.texture = load(bg_path)
		elif FileAccess.file_exists("res://assets/maps/boss_arena_bg.jpg"):
			arena_wallpaper.texture = load("res://assets/maps/boss_arena_bg.jpg")

	# 2. Configure Boss, Particles, Atmosphere, and Thematics per World
	if cur_lvl == 6:
		if boss_sprite:
			boss_sprite.texture = load("res://assets/sprites/custom/boss_segfault_sheet.png")
		if boss_tag:
			boss_tag.text = "👑 Lord SegFault [Null Sovereign]"
		if boss_title:
			boss_title.text = "👑 FINAL BOSS: LORD SEGFAULT, THE NULL SOVEREIGN"
			boss_title.add_theme_color_override("font_color", Color("#E879F9"))
		if vortex_particles:
			vortex_particles.color = Color(0.95, 0.2, 0.65, 0.92)
		if stage_embers:
			stage_embers.color = Color(0.4, 0.9, 1.0, 0.9)
		if brazier_left:
			brazier_left.modulate = Color(0.95, 0.3, 0.85)
		if brazier_right:
			brazier_right.modulate = Color(0.35, 0.85, 1.0)
	elif cur_lvl == 5:
		if boss_sprite:
			boss_sprite.texture = load("res://assets/sprites/custom/boss_guardian_sheet.png")
		if boss_tag:
			boss_tag.text = "🐉 Ignis-Py [Final Boss]"
		if boss_title:
			boss_title.text = "🌋 FINAL BOSS: IGNIS-PY, THE GUARDIAN OF PYTHONIA"
			boss_title.add_theme_color_override("font_color", Color("#FB7185"))
		if vortex_particles:
			vortex_particles.color = Color(1.0, 0.35, 0.15, 0.9)
		if stage_embers:
			stage_embers.color = Color(1.0, 0.78, 0.2, 0.9)
		if brazier_left:
			brazier_left.modulate = Color(1.0, 0.45, 0.25)
		if brazier_right:
			brazier_right.modulate = Color(1.0, 0.45, 0.25)
	elif cur_lvl == 4:
		if boss_sprite:
			boss_sprite.texture = load("res://assets/sprites/custom/boss_index_warden_sheet.png")
		if boss_tag:
			boss_tag.text = "🏺 Vektor-Zero [Boss]"
		if boss_title:
			boss_title.text = "🏺 WORLD 4 BOSS: VEKTOR-ZERO, THE CATACOMB SEQUENCE LICH"
			boss_title.add_theme_color_override("font_color", Color("#F59E0B"))
		if vortex_particles:
			vortex_particles.color = Color(1.0, 0.75, 0.2, 0.85)
		if stage_embers:
			stage_embers.color = Color(0.3, 0.92, 0.55, 0.8)
		if brazier_left:
			brazier_left.modulate = Color(1.0, 0.9, 0.45)
		if brazier_right:
			brazier_right.modulate = Color(1.0, 0.9, 0.45)
	elif cur_lvl == 3:
		if boss_sprite:
			boss_sprite.texture = load("res://assets/sprites/custom/boss_arbiter_sheet.png")
		if boss_tag:
			boss_tag.text = "🔮 Lambda-Prime [Boss]"
		if boss_title:
			boss_title.text = "🔮 WORLD 3 BOSS: LAMBDA-PRIME, THE MODULAR RELIC SOVEREIGN"
			boss_title.add_theme_color_override("font_color", Color("#C084FC"))
		if vortex_particles:
			vortex_particles.color = Color(0.85, 0.4, 1.0, 0.85)
		if stage_embers:
			stage_embers.color = Color(0.95, 0.8, 0.3, 0.8)
		if brazier_left:
			brazier_left.modulate = Color(0.85, 0.55, 1.0)
		if brazier_right:
			brazier_right.modulate = Color(0.85, 0.55, 1.0)
	elif cur_lvl == 2:
		if boss_sprite:
			boss_sprite.texture = load("res://assets/sprites/custom/boss_warden_sheet.png")
		if boss_tag:
			boss_tag.text = "⏳ Chronos-If [Boss]"
		if boss_title:
			boss_title.text = "⏳ WORLD 2 BOSS: CHRONOS-IF, THE INFINITE LOOP WARDEN"
			boss_title.add_theme_color_override("font_color", Color("#38BDF8"))
		if vortex_particles:
			vortex_particles.color = Color(0.2, 0.82, 1.0, 0.85)
		if stage_embers:
			stage_embers.color = Color(0.25, 0.95, 0.85, 0.8)
		if brazier_left:
			brazier_left.modulate = Color(0.45, 0.9, 1.0)
		if brazier_right:
			brazier_right.modulate = Color(0.45, 0.9, 1.0)
	else:
		if boss_sprite:
			boss_sprite.texture = load("res://assets/sprites/custom/boss_golem_sheet.png")
		if boss_tag:
			boss_tag.text = "⚔️ NullByte [Boss]"
		if boss_title:
			boss_title.text = "👾 WORLD 1 BOSS: NULLBYTE, THE DARK SYNTAX KNIGHT"
			boss_title.add_theme_color_override("font_color", Color("#F43F5E"))
		if vortex_particles:
			vortex_particles.color = Color(0.75, 0.5, 1.0, 0.8)
		if stage_embers:
			stage_embers.color = Color(0.4, 0.85, 1.0, 0.75)
		if brazier_left:
			brazier_left.modulate = Color.WHITE
		if brazier_right:
			brazier_right.modulate = Color.WHITE

	if boss_node:
		boss_node.position = boss_start_pos
		boss_node.scale = Vector2.ONE
		boss_node.modulate = Color.WHITE
	if boss_sprite:
		boss_sprite.flip_h = true
		boss_sprite.modulate = Color.WHITE
		boss_sprite.frame = 6

	var chest_label = get_node_or_null("TreasureChest/ChestLabel") as Label
	if chest_label:
		if cur_lvl == 6:
			chest_label.text = "🔒 Princess Ada's Glitch Prism"
		elif cur_lvl == 5:
			chest_label.text = "🔒 Crown of Pythonia Grand Chest"
		elif cur_lvl == 4:
			chest_label.text = "🔒 Pharaonic Sequence Sarcophagus"
		elif cur_lvl == 3:
			chest_label.text = "🔒 Vault Sovereign Arcane Chest"
		elif cur_lvl == 2:
			chest_label.text = "🔒 Chronos Chronometer Chest"
		else:
			chest_label.text = "🔒 Grand Syntax Relic Chest"

	if chest:
		chest.frame = 0
	if alex:
		alex.position = alex_start_pos
		alex.can_move = false
		if "stage_controlled" in alex:
			alex.stage_controlled = true
		if alex.has_method("revive"):
			alex.revive()
		if alex.has_node("Camera2D"):
			alex.get_node("Camera2D").enabled = false
		alex.face_direction(false)
		alex.play_anim("side_idle")
	if float_label:
		float_label.visible = false
	if chest_particles:
		chest_particles.emitting = false
