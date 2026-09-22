extends "res://scripts/entities/interactable.gd"
class_name PressurePlate
## 压力板：站上/压上重物则触发（开门/给奖励）

signal activated
signal deactivated

@export var plate_id := "plate"
var pressed := false
var _block: Node2D = null

func _ready() -> void:
	display_name = "压力板"
	color = Color("#C0A060")
	size = Vector2(28, 16)
	super._ready()

func _process(_delta: float) -> void:
	var now := _check_pressed()
	if now != pressed:
		pressed = now
		if pressed:
			activated.emit()
			Sfx.play("click")
			EventBus.toast.emit("压力板触发！")
		else:
			deactivated.emit()
		queue_redraw()

func _check_pressed() -> bool:
	if _block != null and is_instance_valid(_block):
		if global_position.distance_to(_block.global_position) < 22.0:
			return true
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if global_position.distance_to(p.global_position) < 20.0:
			return true
	return false

func bind_block(b: Node2D) -> void:
	_block = b

func interact(_player: Node) -> void:
	EventBus.toast.emit("压力板：把箱子推上来，或自己站上去。")

func prompt() -> String:
	return "E：压力板（%s）" % ("已触发" if pressed else "未触发")

func _draw() -> void:
	var c := color if not pressed else color.lightened(0.25)
	draw_rect(Rect2(-size * 0.5, size), c)
	draw_rect(Rect2(-size * 0.5, size), c.darkened(0.35), false, 2.0)
