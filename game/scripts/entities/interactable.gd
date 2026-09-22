extends Node2D
class_name Interactable
## 可交互实体基类（出货箱、工作台、床、NPC、资源点）

@export var display_name := "物体"
@export var interact_radius := 42.0
@export var color := Color("#C4A574")
@export var size := Vector2(28, 28)

func _ready() -> void:
	queue_redraw()

func interact(_player: Node) -> void:
	pass

func prompt() -> String:
	return "E：%s" % display_name

func _draw() -> void:
	draw_rect(Rect2(-size * 0.5, size), color)
	draw_rect(Rect2(-size * 0.5, size), color.darkened(0.3), false, 2.0)
