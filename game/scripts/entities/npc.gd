extends "res://scripts/entities/interactable.gd"
class_name Npc
## 简单 NPC：对话 / 送礼

@export var npc_id := "grandpa_lin"

var _met := false
## 行走帧（art/chars/walk/npc_<id>_down_00.png），取不到就走程序化绘制兜底
var _sprite: Texture2D

func _ready() -> void:
	var data := NpcDb.get_npc(npc_id)
	display_name = str(data.get("name", npc_id))
	color = Color.html(str(data.get("color", "#CCC")))
	size = Vector2(20, 28)
	var pos = data.get("position", {})
	# 位置由 World 设置；这里只保底
	if pos is Dictionary and global_position == Vector2.ZERO:
		global_position = Vector2(float(pos.get("x", 0)), float(pos.get("y", 0)))
	var t: Texture2D = ArtPipeline.npc_walk(npc_id, "down", 0)
	if t != null and t.get_width() >= 8 and t.get_height() >= 8:
		_sprite = t
	super._ready()

func interact(_player: Node) -> void:
	var key := "default"
	if not GameState.has_met(npc_id):
		key = "first_meet"
		GameState.meet(npc_id)
		GameState.add_friendship(npc_id, 5)
	# 若选中礼物则送礼
	var gift_id := _held_gift()
	if gift_id != "":
		_give_gift(gift_id)
		return
	var lines: Array = NpcDb.get_dialogue_lines(npc_id, key)
	QuestLog.mark("talk")
	var heart := HeartDb.try_trigger(npc_id)
	if not heart.is_empty():
		GameState.add_friendship(npc_id, int(heart.get("reward", {}).get("friendship", 5)))
		lines = heart.get("lines", lines)
		EventBus.toast.emit("心事件：%s" % str(heart.get("title", "")))
	var fp := GameState.friendship_of(npc_id)
	if fp >= 90:
		lines.append("（羁绊已达最深处 · 终生挚友）")
	elif fp >= 50:
		lines.append("（羁绊很深）")
	elif fp >= 20:
		lines.append("（已成为朋友）")
	EventBus.dialogue_started.emit(lines.duplicate(), npc_id)

func _held_gift() -> String:
	# 灰盒：若背包有喜好物品则自动当礼物（后续可改为选中快捷栏）
	# 这里改为：手持快捷由 Inventory 第一个非工具可送物 — 简化为交互时不自动送
	return ""

func give_selected_gift(item_id: String) -> void:
	_give_gift(item_id)

func _give_gift(item_id: String) -> void:
	if not Inventory.has_item(item_id, 1):
		return
	Inventory.remove_item(item_id, 1)
	var lines: Array
	if NpcDb.is_liked(npc_id, item_id):
		GameState.add_friendship(npc_id, 15)
		lines = NpcDb.get_dialogue_lines(npc_id, "liked_gift")
		EventBus.toast.emit("%s 很喜欢这份礼物！" % display_name)
	elif NpcDb.is_disliked(npc_id, item_id):
		GameState.add_friendship(npc_id, -5)
		lines = NpcDb.get_dialogue_lines(npc_id, "disliked_gift")
		EventBus.toast.emit("%s 似乎不太喜欢……" % display_name)
	else:
		GameState.add_friendship(npc_id, 5)
		lines = ["谢谢你。", "我会好好收着的。"]
		EventBus.toast.emit("送给 %s：%s" % [display_name, ItemDb.item_name(item_id)])
	EventBus.dialogue_started.emit(lines, npc_id)

func prompt() -> String:
	return "E：与 %s 聊天" % display_name

func _draw() -> void:
	if _sprite:
		# 帧是脚底对齐的，底边落在 y=+14（与灰盒矩形底边一致）
		draw_texture_rect(_sprite, Rect2(-10, -16, 20, 30), false)
	else:
		draw_rect(Rect2(-size * 0.5, size), color)
		draw_rect(Rect2(-size * 0.5, size), Color.html(str(NpcDb.get_npc(npc_id).get("accent", "#333"))), false, 2.0)
		# 头
		draw_circle(Vector2(0, -14), 8.0, color.lightened(0.15))
	# 名牌
	draw_string(ThemeDB.fallback_font, Vector2(-20, 34), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
