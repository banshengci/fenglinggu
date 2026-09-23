extends Node2D
## 风蚀迷宫：每次进入随机 3 层，不掉落存档物，Boss 掉星风铃部件

const MineRockScript := preload("res://scripts/entities/mine_rock.gd")
const ChestScript := preload("res://scripts/entities/treasure_chest.gd")
const EnemyScript := preload("res://scripts/entities/mine_enemy.gd")
const PortalScript := preload("res://scripts/entities/area_portal.gd")

const MAX_FLOORS := 3

@export var floor_index := 0

var player: CharacterBody2D
var maze_session: Dictionary = {}
var enemies_root: Node2D
var props_root: Node2D
var _seed := 0

func _ready() -> void:
	add_to_group("mine_level")
	if maze_session.is_empty():
		_seed = randi() % 100000
		maze_session["seed"] = _seed
	else:
		_seed = int(maze_session.get("seed", 0))
	queue_redraw()
	_build()

func _build() -> void:
	props_root = Node2D.new()
	enemies_root = Node2D.new()
	add_child(props_root)
	add_child(enemies_root)

	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + floor_index * 31

	var up = PortalScript.new()
	up.target_area = "cliff_top" if floor_index == 0 else "maze"
	up.target_floor = 0 if floor_index == 0 else floor_index - 1
	up.custom_label = "退出迷宫" if floor_index == 0 else "返回上一层"
	up.position = Vector2(60, 400)
	props_root.add_child(up)

	if floor_index < MAX_FLOORS - 1:
		var down = PortalScript.new()
		down.target_area = "maze"
		down.target_floor = floor_index + 1
		down.custom_label = "深入风蚀层"
		down.position = Vector2(1180, 400)
		props_root.add_child(down)

	if maze_session.has(str(floor_index)):
		_spawn_from_session()
		return

	var rocks: Array = []
	var chests: Array = []
	var foes: Array = []

	# 随机岩柱阵
	var rock_n := 6 + rng.randi_range(0, 4)
	for i in rock_n:
		var pos := _rand_pos(rng, 200, 1100, 120, 620)
		rocks.append({"ore": "stone", "pos": [pos.x, pos.y], "hp": 2})

	# 宝箱
	var chest_n := 1 if floor_index < MAX_FLOORS - 1 else 0
	for i in chest_n:
		var cpos := _rand_pos(rng, 250, 1000, 150, 600)
		chests.append({"pos": [cpos.x, cpos.y], "opened": false})

	# 风蚀怪
	var foe_n := 2 + floor_index
	for i in foe_n:
		var fpos := _rand_pos(rng, 300, 1050, 150, 600)
		foes.append({"type": "slime", "pos": [fpos.x, fpos.y], "hp": 3 + floor_index})

	# 末层 Boss：星风守卫
	if floor_index == MAX_FLOORS - 1:
		foes.append({
			"type": "boss",
			"pos": [1000, 300],
			"hp": 18,
			"boss": true,
		})

	maze_session[str(floor_index)] = {
		"rocks": rocks,
		"chests": chests,
		"foes": foes,
	}
	_spawn_from_session()

func _spawn_from_session() -> void:
	var s: Dictionary = maze_session.get(str(floor_index), {})
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
		var foe = EnemyScript.new()
		var boss := bool(f.get("boss", false))
		var ftype := str(f.get("type", "slime"))
		var fdata := {
			"hp": int(f.get("hp", 3)),
			"touch_damage": 2 if boss else 1,
			"speed": 55.0 if boss else 40.0,
			"color": "#C060E0" if boss else "#7BC96F",
			"size": 22.0 if boss else 14.0,
			"loot": {"star_bell_part": 1} if boss else {},
		}
		foe.setup(ftype, fdata)
		foe.position = Vector2(float(f["pos"][0]), float(f["pos"][1]))
		if boss:
			foe.died.connect(func(_e): on_boss_defeated())
		enemies_root.add_child(foe)

func _rand_pos(rng: RandomNumberGenerator, x0: float, x1: float, y0: float, y1: float) -> Vector2:
	return Vector2(rng.randf_range(x0, x1), rng.randf_range(y0, y1))

func _draw() -> void:
	# 风蚀灰绿底 + 裂纹感
	draw_rect(Rect2(-200, -200, 1800, 1000), Color("#3A4A42"))
	for i in 12:
		var y := 40.0 + i * 55.0
		draw_line(Vector2(0, y), Vector2(1280, y + 18), Color("#2A3A32"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(40, 48), "风蚀迷宫 · 第 %d/%d 层" % [floor_index + 1, MAX_FLOORS],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#E8F0F5"))

## Boss 击杀：掉星风铃部件（由 mine_enemy 回调或手动调用）
func on_boss_defeated() -> void:
	Inventory.add_item("star_bell_part", 1)
	EventBus.toast.emit("获得星风铃部件！")
	EventBus.dialogue_started.emit(["风蚀守卫散作星尘，一枚星风铃部件落入掌心。"], "system")

func get_session() -> Dictionary:
	return maze_session

func set_session(s: Dictionary) -> void:
	maze_session = s
	if s.has("seed"):
		_seed = int(s.get("seed", 0))
