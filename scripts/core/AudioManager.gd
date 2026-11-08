# res://scripts/core/AudioManager.gd
extends Node

const SFX_SPELL_CAST: String = "res://assets/audio/sfx_spell_cast.wav"
const SFX_BOSS_HIT: String = "res://assets/audio/sfx_boss_hit.wav"
const SFX_PLAYER_HURT: String = "res://assets/audio/sfx_player_hurt.wav"
const SFX_ERROR: String = "res://assets/audio/sfx_error.wav"
const SFX_BOSS_DEFEAT: String = "res://assets/audio/sfx_boss_defeat.wav"
const SFX_SHRINE_AWAKEN: String = "res://assets/audio/sfx_shrine_awaken.wav"
const SFX_CHEST_OPEN: String = "res://assets/audio/sfx_chest_open.wav"
const SFX_BRIDGE_EXTEND: String = "res://assets/audio/sfx_bridge_extend.wav"
const SFX_TELEPORT: String = "res://assets/audio/sfx_teleport.wav"
const SFX_RELIC_PICKUP: String = "res://assets/audio/sfx_relic_pickup.wav"
const SFX_NPC_CHAT: String = "res://assets/audio/sfx_npc_chat.wav"
const SFX_CHIME: String = "res://assets/audio/sfx_chime.wav"
const SFX_BADGE_UNLOCK: String = "res://assets/audio/sfx_badge_unlock.wav"
const SFX_FOOTSTEP_1: String = "res://assets/audio/sfx_footstep_1.wav"
const SFX_FOOTSTEP_2: String = "res://assets/audio/sfx_footstep_2.wav"

const SFX_POOL_SIZE: int = 12

var _footstep_toggle: bool = false

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0

# Dedicated channels so high-frequency and celebratory audio never cut each other off
var footstep_player: AudioStreamPlayer
var badge_player: AudioStreamPlayer

var current_track_path: String = ""
var sfx_cache: Dictionary = {}

var master_volume: float = 1.0 # 0.0 to 1.0
var music_volume: float = 0.8  # 0.0 to 1.0
var sfx_volume: float = 1.0    # 0.0 to 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	# Dedicated badge & jingle player (uninterruptible by footsteps or combat effects)
	badge_player = AudioStreamPlayer.new()
	badge_player.name = "BadgePlayer"
	badge_player.bus = "Master"
	add_child(badge_player)
	
	# Dedicated footstep player (plays walking sounds on its own channel)
	footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "FootstepPlayer"
	footstep_player.bus = "Master"
	add_child(footstep_player)
	
	# General SFX polyphonic pool (allows multiple sound effects to overlap naturally)
	sfx_pool.clear()
	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "Master"
		add_child(p)
		sfx_pool.append(p)
	
	if sfx_pool.size() > 0:
		sfx_player = sfx_pool[0]
	
	apply_initial_settings()
	_preload_core_sfx()

func _preload_core_sfx() -> void:
	var sound_paths = [
		SFX_SPELL_CAST, SFX_BOSS_HIT, SFX_PLAYER_HURT, SFX_ERROR,
		SFX_BOSS_DEFEAT, SFX_SHRINE_AWAKEN, SFX_CHEST_OPEN,
		SFX_BRIDGE_EXTEND, SFX_TELEPORT, SFX_RELIC_PICKUP,
		SFX_NPC_CHAT, SFX_CHIME, SFX_BADGE_UNLOCK,
		SFX_FOOTSTEP_1, SFX_FOOTSTEP_2
	]
	for p in sound_paths:
		if ResourceLoader.exists(p):
			sfx_cache[p] = load(p)

func apply_initial_settings() -> void:
	var settings = SaveManager.user_profile.get("settings", {})
	if typeof(settings) == TYPE_DICTIONARY:
		master_volume = float(settings.get("master_volume", 1.0))
		music_volume = float(settings.get("music_volume", 0.8))
		sfx_volume = float(settings.get("sfx_volume", 1.0))
	
	set_master_volume(master_volume)
	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)

## Converts a 0.0 to 1.0 linear slider value into decibels using a psychoacoustic power curve.
## Human hearing is logarithmic; raw linear_to_db(0.5) is only -6 dB (still perceived as loud).
## Using a power curve of 2.8 properly shapes the volume taper:
## - 100% (1.0) -> 0.0 dB (full volume)
## - 75%  (0.75)-> -7.0 dB (comfortably lower)
## - 50%  (0.50)-> -16.8 dB (clear, gentle background level)
## - 25%  (0.25)-> -33.7 dB (soft whisper)
## - 10%  (0.10)-> -56.0 dB (faint ambient)
## - <= 1%      -> -80.0 dB (muted)
static func volume_to_db(vol: float) -> float:
	if vol <= 0.01:
		return -80.0
	var clamped: float = clampf(vol, 0.0, 1.0)
	var curved: float = pow(clamped, 2.8)
	return linear_to_db(curved)

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx != -1:
		if master_volume <= 0.01:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, volume_to_db(master_volume))

func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	if bgm_player:
		bgm_player.volume_db = volume_to_db(music_volume)

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	var db = volume_to_db(sfx_volume)
	if sfx_player:
		sfx_player.volume_db = db
	for p in sfx_pool:
		if is_instance_valid(p):
			p.volume_db = db
	if footstep_player:
		footstep_player.volume_db = volume_to_db(sfx_volume * 0.7)
	if badge_player:
		badge_player.volume_db = db

func play_sfx(path: String = SFX_CHIME, pitch_scale: float = 1.0) -> void:
	if sfx_volume <= 0.01:
		return
	if not sfx_cache.has(path):
		if ResourceLoader.exists(path):
			sfx_cache[path] = load(path)
		else:
			return
	var stream = sfx_cache.get(path)
	if not stream:
		return

	# Find an idle player in the SFX pool, or take round-robin so SFX never cut each other off
	var target_player: AudioStreamPlayer = null
	for p in sfx_pool:
		if is_instance_valid(p) and not p.playing:
			target_player = p
			break

	if not target_player and sfx_pool.size() > 0:
		target_player = sfx_pool[_sfx_pool_index % sfx_pool.size()]
		_sfx_pool_index = (_sfx_pool_index + 1) % sfx_pool.size()

	if target_player:
		target_player.pitch_scale = pitch_scale
		target_player.volume_db = volume_to_db(sfx_volume)
		target_player.stream = stream
		target_player.play()

# Dedicated Helper Functions
func play_spell_cast() -> void:
	play_sfx(SFX_SPELL_CAST)

func play_boss_hit() -> void:
	play_sfx(SFX_BOSS_HIT)

func play_player_hurt() -> void:
	play_sfx(SFX_PLAYER_HURT)

func play_error() -> void:
	play_sfx(SFX_ERROR)

func play_boss_defeat() -> void:
	play_sfx(SFX_BOSS_DEFEAT)

func play_shrine_awaken() -> void:
	play_sfx(SFX_SHRINE_AWAKEN)

func play_chest_open() -> void:
	play_sfx(SFX_CHEST_OPEN)

func play_bridge_extend() -> void:
	play_sfx(SFX_BRIDGE_EXTEND)

func play_teleport() -> void:
	play_sfx(SFX_TELEPORT)

func play_relic_pickup() -> void:
	play_sfx(SFX_RELIC_PICKUP)

func play_npc_chat() -> void:
	play_sfx(SFX_NPC_CHAT)

func play_badge_unlock() -> void:
	if sfx_volume <= 0.01:
		return
	if not sfx_cache.has(SFX_BADGE_UNLOCK):
		if ResourceLoader.exists(SFX_BADGE_UNLOCK):
			sfx_cache[SFX_BADGE_UNLOCK] = load(SFX_BADGE_UNLOCK)
	var stream = sfx_cache.get(SFX_BADGE_UNLOCK)
	if stream and badge_player:
		badge_player.pitch_scale = 1.0
		badge_player.volume_db = volume_to_db(sfx_volume)
		badge_player.stream = stream
		badge_player.play()

func play_footstep() -> void:
	if sfx_volume <= 0.01:
		return
	_footstep_toggle = !_footstep_toggle
	var sfx = SFX_FOOTSTEP_1 if _footstep_toggle else SFX_FOOTSTEP_2
	var random_pitch = randf_range(0.92, 1.08)

	if not sfx_cache.has(sfx):
		if ResourceLoader.exists(sfx):
			sfx_cache[sfx] = load(sfx)
	var stream = sfx_cache.get(sfx)
	if stream and footstep_player:
		footstep_player.pitch_scale = random_pitch
		footstep_player.volume_db = volume_to_db(sfx_volume * 0.7)
		footstep_player.stream = stream
		footstep_player.play()

## Plays background music seamlessly. If the same track is already playing, it will NOT restart.
## from_pos: Starting timestamp in seconds (e.g. 0.01 to skip initial silence)
func play_bgm(stream: AudioStream, from_pos: float = 0.0) -> void:
	if stream == null:
		return
	
	if bgm_player.stream == stream and bgm_player.playing:
		return # Already playing this track uninterrupted!
	
	current_track_path = stream.resource_path
	bgm_player.stream = stream
	bgm_player.volume_db = volume_to_db(music_volume)
	bgm_player.play(from_pos)

## Convenience helper to play BGM by its res:// path
## from_pos: Starting timestamp in seconds
func play_bgm_by_path(path: String, from_pos: float = 0.0) -> void:
	if current_track_path == path and bgm_player.playing:
		return # Already playing this track uninterrupted!
	
	var stream = load(path)
	if stream:
		# Ensure looping is enabled if it's an AudioStreamMP3 or Ogg
		if stream is AudioStreamMP3:
			stream.loop = true
		elif stream is AudioStreamOggVorbis:
			stream.loop = true
		
		play_bgm(stream, from_pos)

## Plays the dedicated boss theme for the specified world (1 to 5).
## Matches "res://assets/audio/world{1-5}_boss_theme.mp3".
## Gracefully falls back to world music or world 1 boss theme if a specific track is not yet added.
func play_boss_theme(world_num: int) -> void:
	var boss_path: String = "res://assets/audio/world%d_boss_theme.mp3" % clampi(world_num, 1, 5)
	if ResourceLoader.exists(boss_path) or FileAccess.file_exists(boss_path):
		play_bgm_by_path(boss_path)
		return
	
	# Fallback if specific boss theme isn't on disk yet
	var world_music_path: String = "res://assets/audio/world%d_music.mp3" % clampi(world_num, 1, 5)
	if ResourceLoader.exists(world_music_path) or FileAccess.file_exists(world_music_path):
		play_bgm_by_path(world_music_path)
	else:
		play_bgm_by_path("res://assets/audio/world1_boss_theme.mp3")

## Stops the current background music
func stop_bgm() -> void:
	bgm_player.stop()
	bgm_player.stream = null
	current_track_path = ""
