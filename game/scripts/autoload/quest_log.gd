extends Node
## 新手引导与目标追踪

signal objectives_changed

const STEPS := [
	{"id": "till", "text": "选中锄头，对荒地按 E 翻地", "done": false},
	{"id": "plant", "text": "选中种子播种", "done": false},
	{"id": "water", "text": "选中水壶浇水", "done": false},
	{"id": "sleep", "text": "回屋在床上按 T 睡觉，进入第二天", "done": false},
	{"id": "harvest", "text": "作物成熟后按 E 收获", "done": false},
	{"id": "sell", "text": "到出货箱卖掉农产品", "done": false},
	{"id": "talk", "text": "和林爷爷聊聊天", "done": false},
	{"id": "mine", "text": "到镇东雾晶矿洞挖点矿", "done": false},
	{"id": "bell", "text": "收集风铃碎片，修复风铃塔", "done": false},
	{"id": "chapter5", "text": "推进主线至风之祭（5 枚风铃）", "done": false},
]

var steps: Array = []
var hints_shown: Dictionary = {}

func _ready() -> void:
	steps = STEPS.duplicate(true)
	EventBus.toast.connect(func(_m): pass)

func mark(id: String) -> void:
	for s in steps:
		if str(s["id"]) == id and not s["done"]:
			s["done"] = true
			EventBus.toast.emit("目标达成：%s" % str(s["text"]))
			objectives_changed.emit()
			return

func sync_story() -> void:
	if StoryDb.bells_repaired > 0:
		mark("bell")
	if StoryDb.festival_done:
		mark("chapter5")

func current_text() -> String:
	for s in steps:
		if not s["done"]:
			if str(s["id"]) == "chapter5":
				return "主线：%s" % StoryDb.current_title()
			return str(s["text"])
	if StoryDb.festival_done:
		return "自由生活：风铃节之后的每一天。"
	return "自由生活：继续种田、探索与修复风铃吧！"

func progress() -> String:
	var n := 0
	for s in steps:
		if s["done"]:
			n += 1
	return "引导 %d/%d" % [n, steps.size()]

func is_tutorial_done() -> bool:
	for s in steps:
		if not s["done"]:
			return false
	return true

func to_dict() -> Dictionary:
	var d := {}
	for s in steps:
		d[str(s["id"])] = bool(s["done"])
	return d

func from_dict(d: Dictionary) -> void:
	for s in steps:
		s["done"] = bool(d.get(str(s["id"]), false))
	objectives_changed.emit()
