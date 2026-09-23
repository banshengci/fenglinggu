extends "res://scripts/entities/interactable.gd"
class_name AreaPortal
## 区域出入口 / 矿洞楼梯

@export var target_area := "town"   # town | mine | sky_farm | sky_cliff
@export var target_floor := 0      # 矿洞层索引，town 为 0
@export var locked := false
@export var lock_hint := "似乎需要先修好风铃。"
@export var custom_label := ""

func _ready() -> void:
	if custom_label != "":
		display_name = custom_label
	else:
		match target_area:
			"mine":
				display_name = "进入雾晶矿洞" if target_floor == 0 else "深入下一层"
			"town":
				display_name = "返回翠谷镇" if target_floor < 0 else "返回地面"
			"sky_farm":
				display_name = "登上浮岛农场"
			"sky_cliff":
				display_name = "前往星风崖"
			_:
				display_name = "通道"
	match target_area:
		"mine":
			color = Color("#8FC0D8")
		"sky_farm", "sky_cliff":
			color = Color("#E8D48A")
		_:
			color = Color("#C4B090")
	size = Vector2(28, 28)
	super._ready()

func set_locked(v: bool, hint := "似乎需要先修好风铃。") -> void:
	locked = v
	lock_hint = hint

func interact(_player: Node) -> void:
	if locked:
		EventBus.dialogue_started.emit([lock_hint], "system")
		return
	get_tree().call_group("area_manager", "travel_to", target_area, target_floor)

func prompt() -> String:
	if locked:
		return "（封闭）%s" % display_name
	return "E：%s" % display_name

func _draw() -> void:
	var r := Rect2(-size * 0.5, size)
	if locked:
		# 未解锁：浅色虚影，避免满屏黑方块
		draw_rect(r, Color(1, 1, 1, 0.08))
		draw_circle(Vector2(0, size.y * 0.5), 8.0, Color(1, 1, 1, 0.12))
		return
	draw_rect(r, color)
	draw_rect(r, color.darkened(0.35), false, 2.0)
	# 箭头
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6, 6), Vector2(6, 6), Vector2(0, -4)
	]), color.lightened(0.3))
