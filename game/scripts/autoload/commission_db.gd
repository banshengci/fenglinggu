extends Node
## 委托板：每日轮换 3 条，可完成领奖

const PATH := "res://data/commissions.json"

var data: Dictionary = {}
var completed: Dictionary = {}  # id -> day completed
var active: Array = []

func _ready() -> void:
	_load()
	refresh_today()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = parsed

func pool() -> Array:
	return data.get("board", [])

func refresh_today() -> void:
	active.clear()
	var all := pool()
	if all.is_empty():
		return
	var day := TimeSystem.day
	# 确定性抽取 3 条
	var indices := range(all.size())
	indices.shuffle()
	# 用日期做种子式筛选
	var picked: Array = []
	for i in all.size():
		var row: Dictionary = all[i]
		var mod := int(row.get("day_mod", 3))
		if day % mod == 0 or picked.size() < 3 and (day + i) % 3 == 0:
			if str(row.get("id")) in completed and int(completed[str(row.get("id"))]) >= day - 1:
				continue
			if not picked.has(row):
				picked.append(row)
		if picked.size() >= 3:
			break
	while picked.size() < 3 and all.size() > 0:
		var row2: Dictionary = all[picked.size() % all.size()]
		if not picked.has(row2):
			picked.append(row2)
		else:
			break
	active = picked

func active_list() -> Array:
	return active

func can_turn_in(row: Dictionary) -> bool:
	return Inventory.count_of(str(row.get("item", ""))) >= int(row.get("count", 1))

func turn_in(row: Dictionary) -> bool:
	if not can_turn_in(row):
		EventBus.toast.emit("材料还不够。")
		return false
	Inventory.remove_item(str(row.get("item", "")), int(row.get("count", 1)))
	var money := int(row.get("reward_money", 0))
	if money > 0:
		Inventory.add_money(money)
	var ritem := str(row.get("reward_item", ""))
	if ritem != "":
		Inventory.add_item(ritem, int(row.get("reward_count", 1)))
	completed[str(row.get("id"))] = TimeSystem.day
	Sfx.play("coin")
	EventBus.toast.emit("委托完成：%s" % str(row.get("text", "")))
	# 从当前列表移除
	active.erase(row)
	return true

func to_dict() -> Dictionary:
	return {"completed": completed.duplicate(), "active": active.duplicate(true)}

func from_dict(d: Dictionary) -> void:
	completed = d.get("completed", {}).duplicate()
	if d.has("active"):
		active = d.get("active", []).duplicate(true)
	else:
		refresh_today()
