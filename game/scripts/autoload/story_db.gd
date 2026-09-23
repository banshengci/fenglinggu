extends Node
## 主线章节与风铃进度

const PATH := "res://data/story.json"

var data: Dictionary = {}
var bells_repaired: int = 0
var festival_done := false
var chapter_flags: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = parsed

func chapters() -> Array:
	return data.get("chapters", [])

func current_chapter() -> Dictionary:
	var idx := clampi(bells_repaired, 0, chapters().size() - 1)
	return chapters()[idx] if chapters().size() > 0 else {}

func chapter_by_id(id: int) -> Dictionary:
	for c in chapters():
		if int(c.get("id", 0)) == id:
			return c
	return {}

func current_title() -> String:
	if festival_done:
		return "自由生活 · 风之祭后"
	return "第 %d 章 · %s" % [int(current_chapter().get("id", 1)), str(current_chapter().get("title", ""))]

func needs() -> Dictionary:
	var c := current_chapter()
	return {
		"shards": int(c.get("shards_needed", 3)),
		"wood": int(c.get("wood_needed", 3)),
		"stone": int(c.get("stone_needed", 0)),
	}

func progress_text() -> String:
	var n := needs()
	var have_s := Inventory.count_of("wind_shard")
	var have_w := Inventory.count_of("wood")
	var have_t := Inventory.count_of("stone")
	return "风铃塔：%s｜碎片 %d/%d 木 %d/%d 石 %d/%d" % [
		str(current_chapter().get("bell_name", "主铃")),
		have_s, n.shards, have_w, n.wood, have_t, n.stone,
	]

func can_repair() -> bool:
	if festival_done:
		return false
	var n := needs()
	return Inventory.count_of("wind_shard") >= n.shards \
		and Inventory.count_of("wood") >= n.wood \
		and Inventory.count_of("stone") >= n.stone

func try_repair() -> bool:
	if not can_repair():
		return false
	var n := needs()
	Inventory.remove_item("wind_shard", n.shards)
	Inventory.remove_item("wood", n.wood)
	if n.stone > 0:
		Inventory.remove_item("stone", n.stone)
	bells_repaired += 1
	var ch := chapter_by_id(bells_repaired)
	if bells_repaired >= chapters().size():
		festival_done = true
		ch = chapter_by_id(chapters().size())
	Sfx.play("bell", 0.65, -3.0)
	QuestLog.mark("bell")
	if festival_done:
		QuestLog.mark("chapter5")
	var lines: Array = ch.get("complete", ["风铃重新响了。"])
	EventBus.dialogue_started.emit(lines, "system")
	EventBus.toast.emit("主线：%s 完成！解锁 %s" % [
		str(ch.get("title", "")), str(ch.get("unlock_label", ""))
	])
	if festival_done:
		EventBus.toast.emit("风之祭达成！进入自由沙盒生活。")
	Bgm.play_track("night" if TimeSystem.hour >= 19 else "town")
	return true

func intro_lines() -> Array:
	return current_chapter().get("intro", [])

func is_area_unlocked(area: String) -> bool:
	if area == "town" or area == "mine":
		return true
	return area in unlocked_areas()

func unlocked_areas() -> Array:
	var out: Array = ["town", "mine"]
	for i in bells_repaired:
		var c := chapter_by_id(i + 1)
		var a := str(c.get("unlock_area", ""))
		if a != "" and a != "festival" and a != "mine":
			out.append(a)
		if a == "deep_mine" or a == "mine":
			out.append("deep_mine")
	# ch1 unlocks mine (already have), ch2 lakeside, ch3 forest, ch4 deep_mine
	if bells_repaired >= 1:
		out.append("mine")
	if bells_repaired >= 2:
		out.append("lakeside")
		out.append("sky_farm")
	if bells_repaired >= 3:
		out.append("sky_cliff")
	if bells_repaired >= 3:
		out.append("forest")
	if bells_repaired >= 4:
		out.append("deep_mine")
	return out

func to_dict() -> Dictionary:
	return {
		"bells_repaired": bells_repaired,
		"festival_done": festival_done,
		"chapter_flags": chapter_flags.duplicate(),
	}

func from_dict(d: Dictionary) -> void:
	bells_repaired = int(d.get("bells_repaired", 0))
	festival_done = bool(d.get("festival_done", false))
	chapter_flags = d.get("chapter_flags", {}).duplicate()
