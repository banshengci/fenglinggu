extends Control
## 触屏端操作层（手机）：左侧虚拟摇杆 + 右侧功能键
## 电脑端默认隐藏，走键鼠/手柄

var _touch_index := -1
var _origin := Vector2.ZERO
var move_vector := Vector2.ZERO

func _ready() -> void:
	var touch_on := DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	visible = touch_on
	set_process_unhandled_input(visible)
	if not visible:
		return
	# 右侧功能键：竖排，大拇指可及
	var col := 1180.0
	_add_btn("交互", Vector2(col, 300), "interact", Vector2(88, 52))
	_add_btn("使用", Vector2(col, 360), "use_tool", Vector2(88, 52))
	_add_btn("风琴", Vector2(col, 420), "open_harp", Vector2(88, 52))
	_add_btn("告白", Vector2(col, 480), "bond_confess", Vector2(88, 52))
	_add_btn("婚礼", Vector2(col, 540), "bond_wedding", Vector2(88, 52))
	_add_btn("背包", Vector2(col, 600), "open_inventory", Vector2(88, 52))
	_add_btn("合成", Vector2(col, 660), "open_craft", Vector2(88, 52))
	_add_btn("地图", Vector2(col, 720), "open_map", Vector2(88, 52))
	_add_btn("关", Vector2(80, 40), "ui_cancel", Vector2(64, 48))

func _add_btn(label: String, pos: Vector2, action: String, sz: Vector2 = Vector2(64, 48)) -> void:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = sz
	b.position = pos - sz * 0.5
	var icon := ArtPipeline.ui("icon_" + action)
	if icon:
		b.icon = icon
	b.pressed.connect(func():
		Input.action_press(action)
		Input.action_release(action)
	)
	add_child(b)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < size.x * 0.45:
			_touch_index = event.index
			_origin = event.position
			move_vector = Vector2.ZERO
			queue_redraw()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			move_vector = Vector2.ZERO
			_release_move()
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		var delta: Vector2 = (event.position - _origin).limit_length(64.0)
		move_vector = delta / 64.0
		_press_move(move_vector)
		queue_redraw()

func _press_move(v: Vector2) -> void:
	if v.x < -0.2:
		Input.action_press("move_left")
	elif v.x > 0.2:
		Input.action_press("move_right")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")
	if v.y < -0.2:
		Input.action_press("move_up")
	elif v.y > 0.2:
		Input.action_press("move_down")
	else:
		Input.action_release("move_up")
		Input.action_release("move_down")

func _release_move() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)

func _draw() -> void:
	if _touch_index < 0:
		return
	draw_circle(_origin, 52.0, Color(1, 1, 1, 0.15))
	draw_circle(_origin + move_vector * 52.0, 24.0, Color(1, 1, 1, 0.35))
