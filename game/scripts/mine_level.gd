extends Node2D
## 矿洞楼层：生成矿岩 / 宝箱 / 敌人 / 楼梯；保留 session 状态

const MineRockScript := preload("res://scripts/entities/mine_rock.gd")
const ChestScript := preload("res://scripts/entities/treasure_chest.gd")
const EnemyScript := preload("res://scripts/entities/mine_enemy.gd")
const PortalScript := preload("res://scripts/entities/area_portal.gd")
const PlateScript := preload("res://scripts/entities/pressure_plate.gd")
const BoxScript := preload("res://scripts/entities/push_box.gd")

@export var floor_index := 0

var player: CharacterBody2D
var mine_session: Dictionary = {}
var enemies_root: Node2D
var props_root: Node2D

var _fl: Dictionary = {}

func _ready() -> void:
	add_to_group("mine_level")
	_fl = MineDb.get_floor(floor_index)
	queue_redraw()
	_build()

func _build() -> void:
	props_root = Node2D.new()
	enemies_root = Node2D.new()
	add_child(props_root)
	add_child(enemies_root)

	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + floor_index * 17

	var up = PortalScript.new()
	up.target_area = "town" if floor_index == 0 else "mine"
	up.target_floor = -1 if floor_index == 0 else floor_index - 1
	up.position = Vector2(60, 400)
	if floor_index == 0:
		up.display_name = "返回翠谷镇"
	else:
		up.display_name = "返回上一层"
	props_root.add_child(up)

	if floor_index < MineDb.floor_count() - 1:
		var down = PortalScript.new()
		down.target_area = "mine"
		down.target_floor = floor_index + 1
		down.position = Vector2(1180, 400)
		down.display_name = "深入下一层"
		props_root.add_child(down)

	if mine_session.has(str(floor_index)):
		_spawn_from_session()
		return

	var rocks: Array = []
	var chests: Array = []
	var foes: Array = []

	var rock_n := int(_fl.get("rock_count", 8))
	for i in rock_n:
		var ore := MineDb.roll_ore(floor_index)
		var pos := _rand_pos(rng, 200, 1100, 120, 620)
		rocks.append({"ore": ore, "pos": [pos.x, pos.y], "hp": 3 if ore != "stone" else 2})

	var chest_n := int(_fl.get("chest_count", 1))
	for i in chest_n:
		var cpos := _rand_pos(rng, 250, 1100, 150, 600)
		chests.append({"pos": [cpos.x, cpos.y], "opened": false})

	var foe_n := int(_fl.get("enemy_count", 0))
	var et := str(_fl.get("enemy_type", "slime"))
	for i in foe_n:
		var fpos := _rand_pos(rng, 300, 1100, 150, 600)
		foes.append({"type": et, "pos": [fpos.x, fpos.y], "hp": int(MineDb.get_enemy(et).get("hp", 3))})

	if str(_fl.get("boss", "")) != "":
		var bpos := Vector2(1000, 300)
		var boss_id := str(_fl.get("boss"))
		foes.append({
			"type": boss_id,
			"pos": [bpos.x, bpos.y],
			"hp": int(MineDb.get_enemy(boss_id).get("hp", 12)),
			"boss": true,
		})

	# 轻量谜题：每 3 层一组压力板 + 石箱
	var puzzles: Array = []
	if floor_index > 0 and floor_index % 3 == 0:
		var ppos := _rand_pos(rng, 400, 900, 200, 500)
		var bpos2 := ppos + Vector2(-80, 40)
		puzzles.append({"plate": [ppos.x, ppos.y], "box": [bpos2.x, bpos2.y], "solved": false})

	mine_session[str(floor_index)] = {
		"rocks": rocks,
		"chests": chests,
		"foes": foes,
		"puzzles": puzzles,
	}
	_spawn_from_session()

func _spawn_from_session() -> void:
	var s: Dictionary = mine_session.get(str(floor_index), {})
	for r in s.get("rocks", []):
		if r.get("gone", false):
			continue
		var rock = MineRockScript.new()
		rock.ore_id = str(r.get("ore", "stone"))
		rock.hp = int(r.get("hp", 2))
		rock.position = Vector2(float(r["pos"][0]), float(r["pos"][1]))
		props_root.add_child(rock)
	for c in s.get("chests", []):
		var chest = ChestScript.new()
		chest.opened = bool(c.get("opened", false))
		chest.position = Vector2(float(c["pos"][0]), float(c["pos"][1]))
		props_root.add_child(chest)
	for f in s.get("foes", []):
		if f.get("dead", false):
			continue
		var type_id := str(f.get("type", "slime"))
		var data := MineDb.get_enemy(type_id)
		var enemy = EnemyScript.new()
		enemy.setup(type_id, data)
		enemy.hp = int(f.get("hp", data.get("hp", 3)))
		enemy.position = Vector2(float(f["pos"][0]), float(f["pos"][1]))
		enemy.died.connect(_on_enemy_died.bind(f))
		enemies_root.add_child(enemy)
	for pz in s.get("puzzles", []):
		if pz.get("solved", false):
			continue
		var plate = PlateScript.new()
		plate.position = Vector2(float(pz["plate"][0]), float(pz["plate"][1]))
		var box = BoxScript.new()
		box.position = Vector2(float(pz["box"][0]), float(pz["box"][1]))
		plate.bind_block(box)
		plate.activated.connect(func():
			pz["solved"] = true
			Inventory.add_item("wind_shard", 1)
			GameState.wind_shards += 1
			EventBus.toast.emit("谜题解开！得到风铃碎片。")
		)
		props_root.add_child(box)
		props_root.add_child(plate)

func _on_enemy_died(_enemy, session_ref: Dictionary) -> void:
	session_ref["dead"] = true

func _rand_pos(rng: RandomNumberGenerator, x0: float, x1: float, y0: float, y1: float) -> Vector2:
	return Vector2(rng.randf_range(x0, x1), rng.randf_range(y0, y1))

func _process(delta: float) -> void:
	_update_hint()
	if player == null or not is_instance_valid(player):
		return
	for e in enemies_root.get_children():
		if e.has_method("hit") and "touch_damage" in e:
			if player.global_position.distance_to(e.global_position) < 18.0:
				var am := get_tree().get_first_node_in_group("area_manager")
				if am:
					var inv: float = float(player.get_meta("iframe", 0.0))
					if inv <= 0.0:
						am.damage_player(int(e.touch_damage))
						player.set_meta("iframe", 0.8)
						player.modulate = Color(1, 0.6, 0.6)
	var inv2: float = float(player.get_meta("iframe", 0.0))
	if inv2 > 0.0:
		inv2 -= delta
		player.set_meta("iframe", inv2)
		if inv2 <= 0.0:
			player.modulate = Color.WHITE

func _update_hint() -> void:
	var hint_node := get_node_or_null("../../../UI/HUD")
	if hint_node == null:
		hint_node = get_node_or_null("../../UI/HUD")
	if hint_node == null or not hint_node.has_method("set_hint"):
		return
	var info := get_focus_info()
	hint_node.set_hint(str(info.get("prompt", "")))

func get_focus_info() -> Dictionary:
	var best := {"kind": "", "target": null, "prompt": "", "dist": 1e9}
	if player == null:
		return best
	var pp: Vector2 = player.global_position
	for e in enemies_root.get_children():
		var d: float = pp.distance_to(e.global_position)
		if d < 56.0 and d < best["dist"]:
			best = {"kind": "enemy", "target": e, "prompt": "E/左键：攻击晶蚀生物", "dist": d}
	for p in props_root.get_children():
		if p.has_method("interact") and p.has_method("prompt"):
			var d2: float = pp.distance_to(p.global_position)
			if d2 <= 48.0 and d2 < best["dist"]:
				best = {"kind": "prop", "target": p, "prompt": p.prompt(), "dist": d2}
	return best

func try_interact() -> void:
	var info := get_focus_info()
	var target = info.get("target")
	if target == null:
		return
	if info["kind"] == "enemy" and target.has_method("hit"):
		target.hit(1)
	elif info["kind"] == "prop":
		target.interact(player)

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("use_tool"):
		try_interact()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var bg := Color.html(str(_fl.get("bg", "#2A3340")))
	var accent := Color.html(str(_fl.get("accent", "#4A5A6A")))
	draw_rect(Rect2(-40, -40, 1360, 800), bg)
	draw_rect(Rect2(40, 40, 1240, 680), accent.darkened(0.2), false, 4.0)
	for i in 12:
		var x := 120.0 + i * 90.0
		draw_circle(Vector2(x, 700 + (i % 3) * 8), 20.0, accent.darkened(0.1))
	draw_string(ThemeDB.fallback_font, Vector2(50, 70),
		"%s  %s" % [str(_fl.get("depth_label", "B?")), str(_fl.get("name", "矿洞"))],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#E8F0E0"))
	draw_string(ThemeDB.fallback_font, Vector2(50, 92),
		"镐子开采 · 靠近敌人按 E/左键攻击 · 楼梯换层",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#A0B0A0"))
