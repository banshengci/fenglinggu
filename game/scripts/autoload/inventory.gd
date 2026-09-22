extends Node
## 背包与经济

const MAX_SLOTS := 24

var money: int = 500
var slots: Array = []  # [{id: String, count: int}, ...]

func _ready() -> void:
	_setup_starting_kit()
	EventBus.inventory_changed.connect(func(): pass)

func _setup_starting_kit() -> void:
	slots.clear()
	money = 500
	add_item("hoe", 1)
	add_item("watering_can", 1)
	add_item("wood_axe", 1)
	add_item("stone_pick", 1)
	add_item("seed_turnip", 6)
	add_item("seed_potato", 3)
	add_item("wood", 5)
	add_item("fiber", 3)

func reset_starting_kit() -> void:
	_setup_starting_kit()
	EventBus.inventory_changed.emit()
	EventBus.money_changed.emit(money)

func get_counts() -> Dictionary:
	var d := {}
	for s in slots:
		d[s["id"]] = int(d.get(s["id"], 0)) + int(s["count"])
	return d

func count_of(id: String) -> int:
	var n := 0
	for s in slots:
		if s["id"] == id:
			n += int(s["count"])
	return n

func has_item(id: String, n: int = 1) -> bool:
	return count_of(id) >= n

func add_item(id: String, count: int = 1) -> bool:
	if count <= 0:
		return false
	# 工具不堆叠超过 1
	if ItemDb.is_tool(id) and count_of(id) >= 1:
		return false
	var remaining := count
	# 先堆叠
	for s in slots:
		if remaining <= 0:
			break
		if s["id"] == id and not ItemDb.is_tool(id):
			s["count"] = int(s["count"]) + remaining
			remaining = 0
	# 再开新格
	while remaining > 0 and slots.size() < MAX_SLOTS:
		var take: int = remaining
		if not ItemDb.is_tool(id):
			take = remaining
		slots.append({"id": id, "count": take})
		remaining = 0
	if remaining > 0:
		EventBus.toast.emit("背包满了！")
		return false
	EventBus.inventory_changed.emit()
	return true

func remove_item(id: String, count: int = 1) -> bool:
	var need := count
	if count_of(id) < need:
		return false
	for i in range(slots.size() - 1, -1, -1):
		if need <= 0:
			break
		var s: Dictionary = slots[i]
		if s["id"] != id:
			continue
		var have := int(s["count"])
		if have <= need:
			need -= have
			slots.remove_at(i)
		else:
			s["count"] = have - need
			need = 0
	EventBus.inventory_changed.emit()
	return true

func add_money(n: int) -> void:
	money += n
	EventBus.money_changed.emit(money)

func spend_money(n: int) -> bool:
	if money < n:
		EventBus.toast.emit("谷币不够……")
		return false
	money -= n
	EventBus.money_changed.emit(money)
	return true

## 出货：按售价结算
func sell_item(id: String, count: int = 1) -> int:
	var price := MarketDb.sell_price(id)
	if price <= 0:
		EventBus.toast.emit("%s 无法出货" % ItemDb.item_name(id))
		return 0
	if not remove_item(id, count):
		return 0
	var gained := price * count
	add_money(gained)
	Sfx.play("coin")
	QuestLog.mark("sell")
	var tip := " 〔集市溢价！〕" if MarketDb.is_premium(id) else ""
	EventBus.toast.emit("出货 %s ×%d，+%d 谷币%s" % [ItemDb.item_name(id), count, gained, tip])
	return gained

func to_dict() -> Dictionary:
	return {
		"money": money,
		"slots": slots.duplicate(true),
	}

func from_dict(d: Dictionary) -> void:
	money = int(d.get("money", 500))
	slots = d.get("slots", []).duplicate(true)
	EventBus.inventory_changed.emit()
	EventBus.money_changed.emit(money)
