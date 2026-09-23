extends Control
## 虚拟摇杆（触屏）

var _touch_index := -1
var _origin := Vector2.ZERO
var move_vector := Vector2.ZERO

func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
	set_process_unhandled_input(visible)
	_add_btn("背包", Vector2(1180, 420), "open_inventory")
	_add_btn("合成", Vector2(1180, 490), "open_craft")
	_add_btn("地图", Vector2(1180, 560), "open_map")
	_add_btn("关", Vector2(1180, 630), "ui_cancel")

func _add_btn(label: String, pos: Vector2, action: String) -> void:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(64, 48)
	b.position = pos - Vector2(32, 24)
	var icon := ArtPipeline.ui("icon_" + action)
	if icon:
		b.icon = icon
	b.pressed.connect(func(): Input.action_press(action); Input.action_release(action))
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
