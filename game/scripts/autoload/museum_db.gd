extends Node
## 博物馆捐赠与图鉴（含蝴蝶 / 风铃音色）

var donated: Dictionary = {}
var discovered: Dictionary = {}
var butterflies: Dictionary = {}
var bell_tones: Dictionary = {}

const BUTTERFLY_SPECIES := [
	"粉蝶", "凤蝶", "斑蝶", "闪蝶", "谷风蝶", "晶纹蝶",
]
const BELL_TONES := {
	"tiny_bell": "清脆铜音",
	"hanging_bells": "叠铃和声",
	"bell_mobile": "风转细响",
	"stone_lantern": "石磬余韵",
	"lantern": "灯下轻响",
	"crystal_lamp": "晶鸣高音",
}

func mark_discover(id: String) -> void:
	if id == "":
		return
	if not discovered.get(id, false):
		discovered[id] = true
		EventBus.toast.emit("图鉴登录：%s" % ItemDb.item_name(id))

func mark_butterfly(species: String = "") -> void:
	var sp := species
	if sp == "":
		sp = BUTTERFLIES_PICK()
	if sp == "" or butterflies.get(sp, false):
		return
	butterflies[sp] = true
	EventBus.toast.emit("蝴蝶图鉴：%s" % sp)

func BUTTERFLIES_PICK() -> String:
	for sp in BUTTERFLY_SPECIES:
		if not butterflies.get(sp, false):
			return sp
	return ""

func mark_bell_tone(furniture_id: String) -> void:
	var tone: String = BELL_TONES.get(furniture_id, "")
	if tone == "" or bell_tones.get(tone, false):
		return
	bell_tones[tone] = true
	EventBus.toast.emit("风铃音色收录：%s" % tone)

func can_donate(id: String) -> bool:
	if donated.get(id, false):
		return false
	var t := ItemDb.get_type(id)
	return t in ["fish", "antique", "crop", "cooked"]

func donate(id: String, count: int = 1) -> bool:
	if not Inventory.has_item(id, count):
		EventBus.toast.emit("身上没有这件藏品")
		return false
	if donated.get(id, false):
		EventBus.toast.emit("馆里已经有一件了")
		return false
	Inventory.remove_item(id, count)
	donated[id] = true
	mark_discover(id)
	Sfx.play("bell", 1.1, -8.0)
	EventBus.toast.emit("捐赠成功：%s（共 %d 件）" % [ItemDb.item_name(id), donate_count()])
	Achievements.check_all()
	return true

func donate_count() -> int:
	return donated.size()

func catalog_text() -> String:
	var lines: PackedStringArray = ["谷之馆 · 图鉴"]
	lines.append("捐赠 %d 件 · 发现 %d 种" % [donate_count(), discovered.size()])
	var kinds := {"crop": 0, "fish": 0, "antique": 0, "cooked": 0}
	for id in discovered:
		var k := ItemDb.get_type(id)
		if kinds.has(k):
			kinds[k] += 1
	lines.append("作物 %d · 鱼 %d · 古物 %d · 料理 %d" % [kinds["crop"], kinds["fish"], kinds["antique"], kinds["cooked"]])
	lines.append("蝴蝶 %d/%d · 风铃音色 %d/%d" % [butterflies.size(), BUTTERFLY_SPECIES.size(), bell_tones.size(), BELL_TONES.size()])
	return "\n".join(lines)

func to_dict() -> Dictionary:
	return {
		"donated": donated.duplicate(),
		"discovered": discovered.duplicate(),
		"butterflies": butterflies.duplicate(),
		"bell_tones": bell_tones.duplicate(),
	}

func from_dict(d: Dictionary) -> void:
	donated = d.get("donated", {}).duplicate()
	discovered = d.get("discovered", {}).duplicate()
	butterflies = d.get("butterflies", {}).duplicate()
	bell_tones = d.get("bell_tones", {}).duplicate()
