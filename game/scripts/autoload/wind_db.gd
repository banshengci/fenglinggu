extends Node
## 风之语：收集、旋律、当日加成

const PATH := "res://data/wind_words.json"

var data: Dictionary = {}
var owned: Dictionary = {}
var sequence: Array = []
var active_buff := ""
var learned_melodies: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = parsed

func words() -> Array:
	return data.get("wind_words", [])

func melodies() -> Array:
	return data.get("melodies", [])

func play_slots() -> int:
	return int(data.get("play_slots", 4))

func word_by_note(note: int) -> Dictionary:
	for w in words():
		if int(w.get("note", -1)) == note:
			return w
	return {}

func owned_count() -> int:
	return owned.size()

func collect_note(note: int) -> bool:
	var w := word_by_note(note)
	if w.is_empty():
		return false
	var id := str(w.get("id", ""))
	if owned.get(id, false):
		EventBus.toast.emit("已听过：" + str(w.get("name", id)))
		return false
	owned[id] = true
	Sfx.play("bell", 1.0 + note * 0.05, -6.0)
	EventBus.toast.emit("风语入册：" + str(w.get("name", id)))
	return true

func try_collect_area(area_id: String) -> void:
	for w in words():
		if str(w.get("where", "")) == area_id and not owned.get(str(w.get("id")), false):
			collect_note(int(w.get("note", 0)))
			return

func press_note(note: int) -> void:
	Sfx.play("bell", 0.8 + note * 0.06, -10.0)
	sequence.append(note)
	if sequence.size() > play_slots():
		sequence.pop_front()
	_check_melody()

func clear_sequence() -> void:
	sequence.clear()

func _check_melody() -> void:
	for m in melodies():
		var notes: Array = m.get("notes", [])
		if notes.size() != sequence.size():
			continue
		var ok := true
		for i in notes.size():
			if int(notes[i]) != int(sequence[i]):
				ok = false
				break
		if ok:
			learned_melodies[str(m.get("id"))] = true
			active_buff = str(m.get("buff", ""))
			GameState.add_flag("wind_buff_growth", active_buff.find("生长") >= 0)
			GameState.add_flag("wind_buff_friend", active_buff.find("好感") >= 0)
			GameState.add_flag("wind_buff_luck", active_buff.find("掉率") >= 0)
			GameState.add_flag("wind_buff_calm", active_buff.find("天气") >= 0)
			Sfx.play("bell", 0.5, -4.0)
			EventBus.toast.emit("风之旋律！" + str(m.get("name")))
			sequence.clear()
			return

func catalog_text() -> String:
	var lines: PackedStringArray = ["风之语 %d/%d" % [owned_count(), words().size()]]
	for w in words():
		var id := str(w.get("id", ""))
		var mark := "O" if owned.get(id, false) else "."
		lines.append("%s %s" % [mark, str(w.get("name", id))])
	lines.append("旋律 %d/%d" % [learned_melodies.size(), melodies().size()])
	if active_buff != "":
		lines.append("加成：" + active_buff)
	return "\n".join(lines)

func to_dict() -> Dictionary:
	return {"owned": owned.duplicate(), "learned": learned_melodies.duplicate(), "buff": active_buff}

func from_dict(d: Dictionary) -> void:
	owned = d.get("owned", {}).duplicate()
	learned_melodies = d.get("learned", {}).duplicate()
	active_buff = str(d.get("buff", ""))
