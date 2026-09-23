extends "res://scripts/entities/interactable.gd"
class_name CouncilBoard
## 议事会告示板：修缮项目

func _ready() -> void:
	display_name = "议事会告示板"
	color = Color("#C4B090")
	size = Vector2(36, 40)
	super._ready()

func interact(_player: Node) -> void:
	var lines: Array = [BondDb.council_summary()]
	for pid in BondDb.council_projects():
		var p: Dictionary = BondDb.council_projects()[pid]
		if BondDb.is_repaired(pid):
			lines.append("✓ %s（已完成）" % str(p.get("name", pid)))
		elif BondDb.can_repair(pid):
			lines.append("可修：%s（木%d 石%d 金%d）按 R 认领" % [
				str(p.get("name", pid)),
				int(p.get("wood", 0)), int(p.get("stone", 0)), int(p.get("gold", 0)),
			])
		else:
			lines.append("缺料：%s（木%d 石%d 金%d）" % [
				str(p.get("name", pid)),
				int(p.get("wood", 0)), int(p.get("stone", 0)), int(p.get("gold", 0)),
			])
	# 自动认领第一项可修的
	for pid in BondDb.council_projects():
		if BondDb.try_repair(pid):
			break
	EventBus.dialogue_started.emit(lines, "system")

func prompt() -> String:
	return "E：%s" % display_name

func _draw() -> void:
	var r := Rect2(-size * 0.5, size)
	draw_rect(r, color)
	draw_rect(r, color.darkened(0.35), false, 2.0)
	draw_rect(Rect2(-size.x * 0.35, 4, size.x * 0.7, 10), Color("#FFF8E0"))
	draw_rect(Rect2(-size.x * 0.35, 18, size.x * 0.7, 10), Color("#E8F0F5"))
