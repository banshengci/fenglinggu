extends Node
## 季节限定活动

const PATH := "res://data/season_events.json"

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

func check_day() -> void:
	var season := TimeSystem.season()
	var day := TimeSystem.day_of_season()
	for e in events():
		if str(e.get("season", "")) != season:
			continue
		if int(e.get("day", 0)) != day:
			continue
		var id := str(e.get("id", ""))
		if seen.get(id, false):
			continue
		seen[id] = true
		_run(e)

func _run(e: Dictionary) -> void:
	var lines: Array = ["【%s】" % str(e.get("title", "活动"))]
	lines.append_array(e.get("lines", []))
	EventBus.dialogue_started.emit(lines, "system")
	var reward: Dictionary = e.get("reward", {})
	if reward.has("money"):
		Inventory.add_money(int(reward["money"]))
	if reward.has("item"):
		Inventory.add_item(str(reward["item"]), int(reward.get("count", 1)))
	Sfx.play("bell", 1.0, -6.0)

func to_dict() -> Dictionary:
	return seen.duplicate()

func from_dict(d: Dictionary) -> void:
	seen = d.duplicate()
