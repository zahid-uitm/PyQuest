# res://scripts/core/AudioManager.gd
extends Node

var bgm_player: AudioStreamPlayer
var current_track_path: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	add_child(bgm_player)

## Plays background music seamlessly. If the same track is already playing, it will NOT restart.
## from_pos: Starting timestamp in seconds (e.g. 0.01 to skip initial silence)
func play_bgm(stream: AudioStream, from_pos: float = 0.0) -> void:
	if stream == null:
		return
	
	if bgm_player.stream == stream and bgm_player.playing:
		return # Already playing this track uninterrupted!
	
	current_track_path = stream.resource_path
	bgm_player.stream = stream
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

## Stops the current background music
func stop_bgm() -> void:
	bgm_player.stop()
	bgm_player.stream = null
	current_track_path = ""
