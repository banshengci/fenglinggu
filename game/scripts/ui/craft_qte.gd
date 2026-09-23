extends CanvasLayer
## 匠心 QTE：烹饪/裁缝/木作 合成前的节奏确认
## 进度条滑入目标区，点按/空格确认；成功才完成合成

signal finished(ok: bool, quality: float)

const BAR_W := 360.0
const BAR_H := 28.0
const TARGET_W := 70.0
const SPEED := 180.0  # px/s

var _t := 0.0
var _cursor := 0.0
var _dir := 1.0
var _target_x := 0.0
var _label := ""
var _active := false
var _root: Control

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	_root.draw.connect(_on_draw)
	_root.set_process_input(true)

func start(label: String) -> void:
	_label = label
	_t = 0.0
	_cursor = 0.0
	_dir = 1.0
	_target_x = randf_range(80.0, BAR_W - TARGET_W - 20.0)
	_active = true
	_root.visible = true
	_root.queue_redraw()
	get_tree().paused = true

func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	_cursor += _dir * SPEED * delta
	if _cursor >= BAR_W:
		_cursor = BAR_W
		_dir = -1.0
	elif _cursor <= 0.0:
		_cursor = 0.0
		_dir = 1.0
	# 超时视为失败
	if _t > 2.8:
		_finish(false, 0.0)
	_root.queue_redraw()

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") \
			or (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		var center := _target_x + TARGET_W * 0.5
		var dist := absf(_cursor - center)
		var ok := dist < TARGET_W * 0.5
		var quality := clampf(1.0 - dist / (TARGET_W * 0.9), 0.0, 1.0)
		_finish(ok, quality)
		get_viewport().set_input_as_handled()

func _finish(ok: bool, quality: float) -> void:
	_active = false
	_root.visible = false
	if get_tree().paused:
		get_tree().paused = false
	finished.emit(ok, quality)

func _on_draw() -> void:
	if not _active:
		return
	var vp := get_viewport().get_visible_rect().size
	var x0 := (vp.x - BAR_W) * 0.5
	var y0 := vp.y * 0.55
	_root.draw_rect(Rect2(x0 - 16, y0 - 48, BAR_W + 32, 96), Color(0, 0, 0, 0.65))
	_root.draw_string(ThemeDB.fallback_font, Vector2(x0, y0 - 20),
		"匠心：%s　在绿区按空格/点按" % _label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#FFF8E0"))
	_root.draw_rect(Rect2(x0, y0, BAR_W, BAR_H), Color("#2A3A32"))
	_root.draw_rect(Rect2(x0 + _target_x, y0, TARGET_W, BAR_H), Color("#6FCF6A"))
	_root.draw_rect(Rect2(x0 + _cursor - 3, y0 - 4, 6, BAR_H + 8), Color("#FFE08A"))
