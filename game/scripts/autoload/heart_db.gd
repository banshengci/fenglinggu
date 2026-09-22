extends Node
## 心事件数据库

const PATH := "res://data/heart_events.json"

var data: Dictionary = {}
var seen: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = parsed

func events() -> Array:
	return data.get("events", [])

func threshold_for(heart: int) -> int:
	var th: Dictionary = data.get("heart_thresholds", {})
	return int(th.get(str(heart), heart * 25))

func try_trigger(npc_id: String) -> Dictionary:
	## 按好感尝试触发未看过的最高心事件
	var fp := GameState.friendship_of(npc_id)
	var best: Dictionary = {}
	for e in events():
		if str(e.get("npc_id", "")) != npc_id:
			continue
		var key := str(e.get("id", ""))
		if seen.get(key, false):
			continue
		var need := threshold_for(int(e.get("heart", 0)))
		if fp >= need:
			if best.is_empty() or int(e.get("heart", 0)) > int(best.get("heart", 0)):
				best = e
	if best.is_empty():
		return {}
	seen[str(best["id"])] = true
	_apply_reward(best.get("reward", {}))
	return best

func _apply_reward(reward: Dictionary) -> void:
	if reward.has("friendship"):
		pass  # 由调用方加
	if reward.has("item"):
		var n := int(reward.get("count", 1))
		Inventory.add_item(str(reward["item"]), n)
	if reward.has("flag"):
		GameState.add_flag(str(reward["flag"]), true)

func to_dict() -> Dictionary:
	return seen.duplicate()

func from_dict(d: Dictionary) -> void:
	seen = d.duplicate()
