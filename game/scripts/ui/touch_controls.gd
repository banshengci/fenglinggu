extends Control
## 触屏端操作层（手机）：左侧虚拟摇杆 + 右侧功能键
## 电脑端默认隐藏，走键鼠/手柄

var _touch_index := -1
var _origin := Vector2.ZERO
var move_vector := Vector2.ZERO

func _ready() -> void:
	add_to_group("touch_controls")
	var touch_on := DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") \
		or OS.get_name() in ["Android", "iOS"]
	visible = touch_on
	set_process_unhandled_input(visible)
	if not visible:
		return
	# 右侧功能键：小号、半透明，尽量少挡画面
	var col := 1220.0
	var y := 120.0
	var sz := Vector2(72, 40)
	for item in [
		["交互", "interact"], ["使用", "use_tool"],
		["风琴", "open_harp"], ["告白", "bond_confess"],
		["婚礼", "bond_wedding"], ["背包", "open_inventory"],
		["合成", "open_craft"], ["地图", "open_map"],
	]:
		_add_btn(item[0], Vector2(col, y), item[1], sz)
		y += 48.0
	_add_btn("关", Vector2(48, 36), "ui_cancel", Vector2(56, 36))

func _add_btn(label: String, pos: Vector2, action: String, sz: Vector2 = Vector2(64, 48)) -> void:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = sz
	b.position = pos - sz * 0.5
	b.modulate = Color(1, 1, 1, 0.82)
	b.add_theme_color_override("font_color", Color("#F3EFE4"))
	b.add_theme_font_size_override("font_size", 13)
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
