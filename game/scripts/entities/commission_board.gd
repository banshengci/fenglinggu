extends "res://scripts/entities/interactable.gd"
class_name CommissionBoard
## 委托板

func _ready() -> void:
	display_name = "委托板"
	color = Color("#D2B48C")
	size = Vector2(30, 36)
	super._ready()

func interact(_player: Node) -> void:
	var list := CommissionDb.active_list()
	if list.is_empty():
		EventBus.dialogue_started.emit(["委托板暂时空着，明天再来看看。"], "system")
		return
	var lines: Array = ["今日委托："]
	for row in list:
		lines.append("· %s（%s ×%d）→ 谷币 %d" % [
			str(row.get("text", "")),
			ItemDb.item_name(str(row.get("item", ""))),
			int(row.get("count", 1)),
			int(row.get("reward_money", 0)),
		])
	# 自动尝试交第一个可完成的
	for row in list:
		if CommissionDb.can_turn_in(row):
			lines.append("—— 正好完成一条！")
			EventBus.dialogue_started.emit(lines, "system")
			CommissionDb.turn_in(row)
			return
	lines.append("（携带足够材料后再来领取报酬）")
	EventBus.dialogue_started.emit(lines, "system")

func prompt() -> String:
	return "E：查看今日委托"
