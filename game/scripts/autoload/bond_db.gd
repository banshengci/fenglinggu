extends Node
## 羁绊进阶：告白 → 伴侣同行 → 婚礼；议事会修缮

const CONFESS_FP := 80
const WEDDING_FP := 120

var partner_id := ""
var stage := 0  # 0=单身 1=情侣 2=已婚
var wedding_done := false
var council_repairs: Dictionary = {}  # 项目 id -> true

func to_dict() -> Dictionary:
	return {
		"partner_id": partner_id,
		"stage": stage,
		"wedding_done": wedding_done,
		"council_repairs": council_repairs.duplicate(),
	}

func from_dict(d: Dictionary) -> void:
	partner_id = str(d.get("partner_id", ""))
	stage = int(d.get("stage", 0))
	wedding_done = bool(d.get("wedding_done", false))
	council_repairs = d.get("council_repairs", {}).duplicate()

func can_confess(npc_id: String) -> bool:
	return stage == 0 and GameState.friendship_of(npc_id) >= CONFESS_FP

func _npc_label(npc_id: String) -> String:
	if NpcDb == null:
		return npc_id
	if NpcDb.has_method("npc_name"):
		return str(NpcDb.npc_name(npc_id))
	if NpcDb.has_method("get_name"):
		return str(NpcDb.get_name(npc_id))
	var info: Dictionary = NpcDb.get_npc(npc_id) if NpcDb.has_method("get_npc") else {}
	return str(info.get("name", npc_id))

func _player_gold() -> int:
	if Inventory != null and "money" in Inventory:
		return int(Inventory.money)
	return 0

func _spend_gold(n: int) -> void:
	if Inventory != null and Inventory.has_method("spend_money"):
		Inventory.spend_money(n)
	elif Inventory != null and "money" in Inventory:
		Inventory.money = maxi(0, int(Inventory.money) - n)
		EventBus.money_changed.emit(int(Inventory.money))

func try_confess(npc_id: String) -> bool:
	if not can_confess(npc_id):
		return false
	partner_id = npc_id
	stage = 1
	GameState.add_friendship(npc_id, 10)
	EventBus.dialogue_started.emit([
		"风把话送到了对方心里。",
		"%s 答应了。从今日起，旅途有伴。" % _npc_label(npc_id),
	], npc_id)
	EventBus.toast.emit("告白成功！%s 成为伴侣" % _npc_label(npc_id))
	EventBus.hud_refresh.emit()
	return true

func can_wedding() -> bool:
	return stage == 1 and partner_id != "" and GameState.friendship_of(partner_id) >= WEDDING_FP

func try_wedding() -> bool:
	if not can_wedding():
		return false
	stage = 2
	wedding_done = true
	GameState.add_friendship(partner_id, 20)
	EventBus.dialogue_started.emit([
		"风铃全谷齐响。",
		"你与 %s 在星风下结为终身伴侣。" % _npc_label(partner_id),
	], "system")
	EventBus.toast.emit("婚礼完成！风铃谷最甜的一天")
	EventBus.hud_refresh.emit()
	return true

func bond_text(npc_id: String) -> String:
	var fp := GameState.friendship_of(npc_id)
	if npc_id == partner_id and stage >= 2:
		return "（终身伴侣）"
	if npc_id == partner_id and stage == 1:
		return "（恋人）"
	if can_confess(npc_id):
		return "（可以告白了）"
	if fp >= 50:
		return "（羁绊很深）"
	return ""

## 议事会修缮项目
const COUNCIL_PROJECTS := {
	"bridge": {"name": "修缮木桥", "wood": 10, "stone": 5, "gold": 200},
	"square": {"name": "翻新广场", "wood": 8, "stone": 8, "gold": 300},
	"bell_path": {"name": "铺风铃石径", "wood": 5, "stone": 12, "gold": 250},
}

func council_projects() -> Dictionary:
	return COUNCIL_PROJECTS

func is_repaired(pid: String) -> bool:
	return bool(council_repairs.get(pid, false))

func can_repair(pid: String) -> bool:
	if is_repaired(pid):
		return false
	var p: Dictionary = COUNCIL_PROJECTS.get(pid, {})
	if p.is_empty():
		return false
	return Inventory.count_of("wood") >= int(p.get("wood", 0)) \
		and Inventory.count_of("stone") >= int(p.get("stone", 0)) \
		and _player_gold() >= int(p.get("gold", 0))

func try_repair(pid: String) -> bool:
	if not can_repair(pid):
		return false
	var p: Dictionary = COUNCIL_PROJECTS[pid]
	Inventory.remove_item("wood", int(p.get("wood", 0)))
	Inventory.remove_item("stone", int(p.get("stone", 0)))
	_spend_gold(int(p.get("gold", 0)))
	council_repairs[pid] = true
	EventBus.toast.emit("议事会：%s 完成！" % str(p.get("name", pid)))
	EventBus.hud_refresh.emit()
	return true

func council_summary() -> String:
	var done := 0
	for pid in COUNCIL_PROJECTS:
		if is_repaired(pid):
			done += 1
	return "议事会修缮 %d/%d" % [done, COUNCIL_PROJECTS.size()]
