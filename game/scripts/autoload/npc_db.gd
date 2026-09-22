extends Node
## NPC 数据库

const PATH := "res://data/npcs.json"

var npcs: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_error("无法读取 npcs.json")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		npcs = parsed

func get_npc(id: String) -> Dictionary:
	return npcs.get(id, {})

func list_ids() -> Array:
	return npcs.keys()

func get_dialogue_lines(id: String, key: String) -> Array:
	var npc := get_npc(id)
	var dialogues: Dictionary = npc.get("dialogues", {})
	return dialogues.get(key, dialogues.get("default", ["……"]))

func is_liked(id: String, item_id: String) -> bool:
	return item_id in get_npc(id).get("likes", [])

func is_disliked(id: String, item_id: String) -> bool:
	return item_id in get_npc(id).get("dislikes", [])
