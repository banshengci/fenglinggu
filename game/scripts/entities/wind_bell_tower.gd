extends "res://scripts/entities/interactable.gd"
class_name WindBellTower
## 风铃塔：主线材料提交与章节推进

func _ready() -> void:
	display_name = "风铃塔"
	color = Color("#A8D8E8")
	size = Vector2(28, 48)
	super._ready()

func interact(_player: Node) -> void:
	if StoryDb.festival_done:
		EventBus.dialogue_started.emit([
			"五铃在风里轻轻应和。",
			"风铃节已经回来了。想怎么过日子都行。",
		], "system")
		return
	var ch := StoryDb.current_chapter()
	if StoryDb.can_repair():
		StoryDb.try_repair()
		return
	var n := StoryDb.needs()
	EventBus.dialogue_started.emit([
		"目标：%s（第 %d 章）" % [str(ch.get("bell_name", "主铃")), int(ch.get("id", 1))],
		"需要：风铃碎片 ×%d（有 %d）· 木材 ×%d（有 %d）· 石块 ×%d（有 %d）" % [
			n.shards, Inventory.count_of("wind_shard"),
			n.wood, Inventory.count_of("wood"),
			n.stone, Inventory.count_of("stone"),
		],
		str(ch.get("title", "")) + "：" + StoryDb.progress_text(),
	], "system")

func prompt() -> String:
	if StoryDb.festival_done:
		return "E：风铃塔（风之祭后）"
	return "E：风铃塔 · %s" % StoryDb.progress_text()
