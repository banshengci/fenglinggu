extends CharacterBody2D
## 玩家：四向移动 + 朝向交互

const SPEED := 140.0

## 行走动画帧率（4 帧循环）。0.14s/帧 ≈ 一个完整步态 0.56s，与脚步音效 0.28s 半拍对齐。
const WALK_FPS := 7.0
const WALK_DIRS := ["down", "left", "right", "up"]

var facing := Vector2.DOWN
var can_move := true
var body_color := Color("#5B8FA8")
var hand_color := Color("#E8C87A")
var _step_t := 0.0

## 四向 × 4 帧缓存。任一方向缺帧则该方向留空，绘制时回退到程序化小人。
var _frames: Dictionary = {}
var _anim_t := 0.0
var _has_walk := false

func _ready() -> void:
	add_to_group("player")
	# 取 art/chars/walk/ 下的规范化行走帧（脚底对齐、全帧统一 scale）。
	# 占位图是 1x1 的，拉伸后会变成一块纯色方块，因此尺寸过小时直接丢弃，
	# 交给 _draw() 的程序化小人绘制。
	for d in WALK_DIRS:
		var arr: Array[Texture2D] = []
		for i in 4:
			var t: Texture2D = ArtPipeline.player_walk(d, i)
			if t != null and t.get_width() >= 8 and t.get_height() >= 8:
				arr.append(t)
		if arr.size() == 4:
			_frames[d] = arr
	_has_walk = _frames.size() == WALK_DIRS.size()
	if not _has_walk:
		_frames = {}

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	if dir.length() > 0.1:
		facing = dir.normalized()
		# 取模回卷，避免长时间游玩后浮点累积导致取帧抖动
		_anim_t = fmod(_anim_t + _delta, 4.0 / WALK_FPS)
		_step_t -= _delta
		if _step_t <= 0.0:
			_step_t = 0.28
			Sfx.play("step", randf_range(0.9, 1.1), -18.0)
	else:
		# 停下即回到静止帧，避免停在抬腿姿势上
		_anim_t = 0.0
	move_and_slide()
	# 限制在扩展后的世界范围内，相机跟随可看到更大地图
	position.x = clampf(position.x, 20.0, 2400.0)
	position.y = clampf(position.y, 20.0, 1500.0)
	_sync_hand_color()
	queue_redraw()

func _sync_hand_color() -> void:
	var ui := get_tree().get_first_node_in_group("inventory_ui")
	if ui and ui.has_method("selected_item_id"):
		var id: String = ui.selected_item_id()
		if id != "":
			hand_color = ItemDb.get_color(id)

func world_interact_point() -> Vector2:
	return global_position + facing * 28.0

func set_control_enabled(enabled: bool) -> void:
	can_move = enabled

## facing -> 方向名。四向优先，斜向按主导轴归并（避免取不到帧）。
func _dir_name() -> String:
	if absf(facing.x) > absf(facing.y):
		return "left" if facing.x < 0.0 else "right"
	return "up" if facing.y < 0.0 else "down"

func _walk_texture() -> Texture2D:
	if not _has_walk:
		return null
	var arr: Array = _frames.get(_dir_name(), [])
	if arr.is_empty():
		return null
	var i: int = int(_anim_t * WALK_FPS) % arr.size()
	return arr[i] as Texture2D

func _draw() -> void:
	var t := _walk_texture()
	if t:
		# 帧是脚底对齐的，绘制时让底边落在 y=+12，与碰撞盒底部基本一致
		draw_texture_rect(t, Rect2(-8, -12, 16, 24), false)
	else:
		draw_rect(Rect2(-9, -8, 18, 22), body_color)
		draw_circle(Vector2(0, -14), 8.0, Color("#F0D0B0"))
	var hand_off := facing * 12.0
	draw_rect(Rect2(hand_off.x - 3, hand_off.y - 3, 8, 8), hand_color)
	draw_circle(facing * 28.0, 2.0, Color(1, 1, 1, 0.35))
