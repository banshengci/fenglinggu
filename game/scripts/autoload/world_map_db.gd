extends Node
## 开放世界地图数据

const PATH := "res://data/world_map.json"

var data: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = parsed

func regions() -> Array:
	return data.get("regions", [])

func region(id: String) -> Dictionary:
	for r in regions():
		if str(r.get("id", "")) == id:
			return r
	return {}

func links() -> Array:
	return data.get("links", [])

func biome_style(id: String) -> Dictionary:
	return data.get("biomes", {}).get(id, {"ground": "#8FB56F", "accent": "#C4B090"})

func is_unlocked(id: String) -> bool:
	var r := region(id)
	if r.is_empty():
		return false
	var need := int(r.get("unlock", 0))
	if need <= 0:
		return true
	if StoryDb.bells_repaired >= need:
		return true
	# 主线完成也可
	return StoryDb.festival_done

func unlocked_ids() -> Array:
	var out: Array = []
	for r in regions():
		if is_unlocked(str(r.get("id", ""))):
			out.append(str(r.get("id", "")))
	return out

func neighbors(id: String) -> Array:
	var out: Array = []
	for link in links():
		if link is Array and link.size() >= 2:
			if str(link[0]) == id:
				out.append(str(link[1]))
			elif str(link[1]) == id:
				out.append(str(link[0]))
	return out

func path_text(player_area: String) -> String:
	var lines: PackedStringArray = ["开放世界 · 风之谷"]
	for r in regions():
		var rid := str(r.get("id", ""))
		var mark := "●" if rid == player_area else ("○" if is_unlocked(rid) else "·")
		lines.append("%s %s（%s）%s" % [mark, str(r.get("name", rid)), str(r.get("biome", "")), str(r.get("desc", ""))])
	lines.append("")
	lines.append("○=可前往 · ·=未解锁 · 选区域名或用 W 键漫游")
	return "\n".join(lines)

## 随机解锁邻接区域（开放漫游）
func pick_wander_target(from_id: String) -> String:
	var ns := neighbors(from_id)
	var open: Array = []
	for n in ns:
		if is_unlocked(n):
			open.append(n)
	if open.is_empty():
		return from_id
	return str(open[randi() % open.size()])
