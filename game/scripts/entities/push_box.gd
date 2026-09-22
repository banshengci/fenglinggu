extends "res://scripts/entities/interactable.gd"
class_name PushBox
## 推箱子：靠近交互推动一小格，可压住压力板

@export var push_step := 28.0
var _cool := 0.0

func _ready() -> void:
	display_name = "石箱"
	color = Color("#8A8A7A")
	size = Vector2(24, 24)
	super._ready()

func interact(player: Node) -> void:
	if _cool > 0.0:
		return
	if player == null:
		return
	var dir: Vector2 = (global_position - player.global_position).normalized()
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	# 只允许四向推动
	if absf(dir.x) > absf(dir.y):
		dir = Vector2(signf(dir.x), 0)
	else:
		dir = Vector2(0, signf(dir.y))
	global_position += dir * push_step
	_cool = 0.35
	Sfx.play("chop", 0.7)
	EventBus.toast.emit("推动了石箱")
	queue_redraw()

func _process(delta: float) -> void:
	if _cool > 0.0:
		_coldown(delta)

func _coldown(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)

func prompt() -> String:
	return "E：推石箱"

func _draw() -> void:
	draw_rect(Rect2(-size * 0.5, size), color)
	draw_rect(Rect2(-size * 0.5, size), color.darkened(0.35), false, 2.0)
	draw_line(Vector2(-6, -4), Vector2(6, 4), Color(0, 0, 0, 0.25), 1.5)
	draw_line(Vector2(-6, 4), Vector2(6, -4), Color(0, 0, 0, 0.25), 1.5)
