extends Node
## 成就系统

const PATH := "res://data/achievements.json"

var unlocked: Dictionary = {}
var stats: Dictionary = {
	"harvest_count": 0,
	"flash_count": 0,
	"mine_count": 0,
	"cook_count": 0,
	"max_floor": 0,
	"legend_fish": 0,
}

func list_all() -> Array:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return []
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		return parsed.get("list", [])
	return []

func add_stat(key: String, n: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + n
	check_all()

func set_stat(key: String, v: int) -> void:
	stats[key] = maxi(int(stats.get(key, 0)), v)
	check_all()

func _condition_met(check: String) -> bool:
	var parts := check.split(">=")
	if parts.size() != 2:
		return false
	var key := parts[0].strip_edges()
	var need := int(parts[1])
	match key:
		"bells":
			return StoryDb.bells_repaired >= need
		"money":
			return Inventory.money >= need
		"donate":
			return MuseumDb.donate_count() >= need
		"friends":
			var n := 0
			for id in GameState.friendship:
				if int(GameState.friendship[id]) >= 20:
					n += 1
			return n >= need
		_:
			return int(stats.get(key, 0)) >= need

func check_all() -> void:
	for a in list_all():
		var id := str(a.get("id", ""))
		if id == "" or unlocked.get(id, false):
			continue
		if _condition_met(str(a.get("check", ""))):
			unlocked[id] = true
			Sfx.play("coin")
			EventBus.toast.emit("成就解锁：%s" % str(a.get("name", id)))

func unlocked_count() -> int:
	return unlocked.size()

func to_dict() -> Dictionary:
	return {"unlocked": unlocked.duplicate(), "stats": stats.duplicate()}

func from_dict(d: Dictionary) -> void:
	unlocked = d.get("unlocked", {}).duplicate()
	var st = d.get("stats", {})
	if st is Dictionary:
		stats = st.duplicate()
