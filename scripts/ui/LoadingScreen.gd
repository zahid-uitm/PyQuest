# res://scripts/ui/LoadingScreen.gd
extends Control

@onready var bg_texture_rect: TextureRect = %Background
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var alex_container: Control = %AlexContainer
@onready var alex_sprite: AnimatedSprite2D = %AlexSprite
@onready var fade_rect: ColorRect = %FadeRect

const BASE_THEMES: Array[String] = [
	"res://assets/loading/loading_bg_generals.jpg",
	"res://assets/loading/loading_bg_ada.jpg",
	"res://assets/loading/loading_bg_alex.jpg",
	"res://assets/loading/loading_bg_pywizard.jpg"
]
const SEGFAULT_THEME: String = "res://assets/loading/loading_bg_segfault.jpg"

var target_scene_path: String = ""
var target_custom_data: Dictionary = {}
var min_display_time: float = 4.0
var elapsed_time: float = 0.0
var visual_progress: float = 0.0
var is_loading_finished: bool = false
var loaded_packed_scene: PackedScene = null

func _ready() -> void:
	# 1. Determine target scene from SceneManager or fallback to MainMenu
	target_scene_path = SceneManager.target_scene_path
	target_custom_data = SceneManager.target_custom_data
	if target_scene_path.is_empty():
		target_scene_path = SceneManager.MAIN_MENU
	
	# 2. Pick a random theme wallpaper
	_apply_random_theme()
	
	# 3. Setup Alex's walking animation programmatically
	_setup_alex_animation()
	
	# 4. Initialize UI state
	progress_bar.value = 0.0
	fade_rect.modulate.a = 1.0
	
	# Fade in from black
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.35)
	
	# 5. Start threaded loading of target scene with sub-threads enabled
	if ResourceLoader.exists(target_scene_path):
		var req_err = ResourceLoader.load_threaded_request(target_scene_path, "", true)
		if req_err != OK:
			push_warning("LoadingScreen: load_threaded_request returned %d, will use synchronous fallback" % req_err)
	else:
		push_error("LoadingScreen: Target scene does not exist: %s" % target_scene_path)

func _process(delta: float) -> void:
	elapsed_time += delta
	
	# Check threaded load status if not already loaded
	if loaded_packed_scene == null and ResourceLoader.exists(target_scene_path):
		var progress_arr: Array = []
		var load_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress_arr)
		
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			loaded_packed_scene = ResourceLoader.load_threaded_get(target_scene_path) as PackedScene
		elif load_status == ResourceLoader.THREAD_LOAD_FAILED or load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			# Fallback synchronous load immediately on error
			loaded_packed_scene = load(target_scene_path) as PackedScene
	
	# Visual pacing: smooth transition across min_display_time
	var time_ratio: float = clampf(elapsed_time / min_display_time, 0.0, 1.0)
	
	# If time reached 85% and background thread hasn't finished, trigger synchronous load fallback
	if loaded_packed_scene == null and time_ratio >= 0.85:
		if ResourceLoader.exists(target_scene_path):
			loaded_packed_scene = load(target_scene_path) as PackedScene
	
	# Desired progress drives smoothly to 1.0
	var desired_progress: float = time_ratio
	if loaded_packed_scene == null:
		desired_progress = minf(time_ratio, 0.90)
	
	# Smoothly interpolate visual progress
	visual_progress = move_toward(visual_progress, desired_progress, delta * 1.5)
	progress_bar.value = visual_progress * 100.0
	
	# Update Alex's walking position along the progress bar
	_update_alex_position()
	
	# Check completion condition: progress >= 99% and minimum display time elapsed
	if not is_loading_finished and visual_progress >= 0.99 and elapsed_time >= min_display_time:
		is_loading_finished = true
		_finish_and_transition()

func _update_alex_position() -> void:
	if not progress_bar or not alex_container:
		return
	
	var bar_width = progress_bar.size.x
	var bar_pos = progress_bar.position
	# Alex container follows the progress head smoothly
	var target_x = bar_pos.x + (bar_width * visual_progress)
	alex_container.position.x = target_x
	alex_container.position.y = bar_pos.y - 18.0

func _setup_alex_animation() -> void:
	if not alex_sprite:
		return
	
	var player_sheet_path = "res://assets/sprites/characters/player.png"
	if not ResourceLoader.exists(player_sheet_path):
		return
	
	var player_sheet = load(player_sheet_path) as Texture2D
	var frames = SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_speed("walk", 9.0)
	frames.set_animation_loop("walk", true)
	
	# 6 frames of walking right at Y=192, 48x48
	for i in range(6):
		var atlas = AtlasTexture.new()
		atlas.atlas = player_sheet
		atlas.region = Rect2(i * 48, 192, 48, 48)
		frames.add_frame("walk", atlas)
	
	# Optional victory frame at the end
	frames.add_animation("victory")
	var victory_atlas = AtlasTexture.new()
	victory_atlas.atlas = player_sheet
	victory_atlas.region = Rect2(0, 0, 48, 48)
	frames.add_frame("victory", victory_atlas)
	
	alex_sprite.sprite_frames = frames
	alex_sprite.play("walk")

func _is_segfault_unlocked() -> bool:
	if SaveManager.is_dev_mode():
		return true
	var profile: Dictionary = SaveManager.user_profile
	var unlocked_lvl: int = int(profile.get("unlocked_level", 1))
	return bool(profile.get("world5_boss_beaten", false)) or unlocked_lvl >= 6 or bool(profile.get("cutscene_ignis_unlocked", false)) or bool(profile.get("world6_unlocked", false))

func _apply_random_theme() -> void:
	var pool: Array[String] = BASE_THEMES.duplicate()
	
	# Lord SegFault is unmasked only after defeating Ignis-Py in Chapter 5
	if _is_segfault_unlocked():
		pool.append(SEGFAULT_THEME)
	
	# Draw from the persistent Shuffle Bag to guarantee no repeats
	var tex_path = SceneManager.get_next_loading_wallpaper(pool)
	if ResourceLoader.exists(tex_path):
		bg_texture_rect.texture = load(tex_path)

func _finish_and_transition() -> void:
	# Switch Alex to cheer / victory pose
	if alex_sprite and alex_sprite.sprite_frames and alex_sprite.sprite_frames.has_animation("victory"):
		alex_sprite.play("victory")
	
	# Smooth fade out transition to target scene
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(fade_rect, "modulate:a", 1.0, 0.3)
	tw.tween_callback(func():
		var final_path = target_scene_path
		SceneManager.target_scene_path = ""
		if loaded_packed_scene:
			get_tree().change_scene_to_packed(loaded_packed_scene)
		else:
			get_tree().change_scene_to_file(final_path)
	)
