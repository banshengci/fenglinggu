extends Node2D
## 通用户外区域：湖畔 / 风车林 / 终局祭典
## area_id: lakeside | forest | festival

const ResourceNodeScript := preload("res://scripts/entities/resource_node.gd")
const PortalScript := preload("res://scripts/entities/area_portal.gd")
const NpcScript := preload("res://scripts/entities/npc.gd")
const ChestScript := preload("res://scripts/entities/treasure_chest.gd")
const FishSpotScript := preload("res://scripts/entities/fish_spot.gd")

var area_id := "lakeside"
var player: CharacterBody2D
var entities_root: Node2D

var _palette := {
	"lakeside": {"ground": Color("#7AA8C8"), "accent": Color("#C8D8E0"), "name": "湖畔栈道", "desc": "湖面很静，小船在轻轻碰岸。"},
	"forest": {"ground": Color("#4A6B3A"), "accent": Color("#8FBC6B"), "name": "旧风车林", "desc": "风车吱呀，树影里藏着旧约。"},
	"festival": {"ground": Color("#C8A86A"), "accent": Color("#E8C87A"), "name": "风铃祭广场", "desc": "彩绳与铃铛把整个广场挂满了声音。"},
	"farm_valley": {"ground": Color("#9BC47A"), "accent": Color("#E8D48A"), "name": "河畔田埂", "desc": "开阔草甸，适合扩种。"},
	"wild_woods": {"ground": Color("#3A5A4A"), "accent": Color("#7BA88A"), "name": "雾林秘境", "desc": "雾里有蘑菇和旧物。"},
	"cliff_top": {"ground": Color("#8A9AAA"), "accent": Color("#C0D0E0"), "name": "风脊崖顶", "desc": "风很大，星星很低。"},
	"pasture": {"ground": Color("#A8C870"), "accent": Color("#E0E8A0"), "name": "南坡牧场", "desc": "动物与牧草的气味。"},
	"mine_camp": {"ground": Color("#5C5C6A"), "accent": Color("#A0A8B0"), "name": "矿营", "desc": "帐篷、炉火与镐子。"},
	"sky_farm": {"ground": Color("#B8D8E8"), "accent": Color("#E8D48A"), "name": "浮岛农场", "desc": "云上的温室，风语花正开。"},
	"sky_cliff": {"ground": Color("#8A9AAA"), "accent": Color("#E8F0F5"), "name": "星风崖", "desc": "离星空最近的风口。"},
}

func _ready() -> void:
	entities_root = Node2D.new()
	add_child(entities_root)
	_build()
	queue_redraw()

func _build() -> void:
	# 回镇
	var back = PortalScript.new()
	back.target_area = "town"
	back.target_floor = 0
	back.display_name = "返回翠谷镇"
	back.position = Vector2(80, 400)
	entities_root.add_child(back)

	match area_id:
		"lakeside":
			_build_lakeside()
		"forest":
			_build_forest()
		"festival":
			_build_festival()
		"pasture":
			_build_pasture()
		"wild_woods":
			_build_wild()
		"cliff_top":
			_build_cliff()
		"mine_camp":
			_build_mine_camp()
		"sky_farm":
			_build_sky_farm()
		"sky_cliff":
			_build_sky_cliff()
		_:
			_build_meadow()

func _build_sky_farm() -> void:
	var shrine = preload("res://scripts/entities/wind_shrine.gd").new()
	shrine.area_id = "sky_farm"
	shrine.position = Vector2(480, 300)
	entities_root.add_child(shrine)
	# 浮岛温室：反季种植田
	var FarmPlotScript = preload("res://scripts/entities/farm_plot.gd")
	for i in range(6):
		for j in range(4):
			var p = FarmPlotScript.new()
			p.grid = Vector2i(i, j)
			p.allow_any_season = true
			p.position = Vector2(200 + i * 40, 360 + j * 40)
			entities_root.add_child(p)
	var chest = ChestScript.new()
	chest.position = Vector2(760, 220)
	entities_root.add_child(chest)
	# 返回镇上 + 通往星风崖
	var PortalScript = preload("res://scripts/entities/area_portal.gd")
	var home = PortalScript.new()
	home.target_area = "town"
	home.target_floor = 0
	home.custom_label = "乘热气球返回翠谷镇"
	home.position = Vector2(120, 200)
	entities_root.add_child(home)
	var to_cliff = PortalScript.new()
	to_cliff.target_area = "sky_cliff"
	to_cliff.target_floor = 0
	to_cliff.custom_label = "前往星风崖"
	to_cliff.position = Vector2(880, 300)
	entities_root.add_child(to_cliff)
	for i in 6:
		var pad = preload("res://scripts/entities/furniture_pad.gd").new()
		pad.position = Vector2(360 + i * 50, 420)
		entities_root.add_child(pad)

func _build_sky_cliff() -> void:
	var shrine = preload("res://scripts/entities/wind_shrine.gd").new()
	shrine.area_id = "sky_cliff"
	shrine.position = Vector2(560, 260)
	entities_root.add_child(shrine)
	var chest = ChestScript.new()
	chest.position = Vector2(900, 360)
	entities_root.add_child(chest)
	var PortalScript = preload("res://scripts/entities/area_portal.gd")
	var home = PortalScript.new()
	home.target_area = "town"
	home.target_floor = 0
	home.custom_label = "乘热气球返回翠谷镇"
	home.position = Vector2(140, 220)
	entities_root.add_child(home)
	var to_farm = PortalScript.new()
	to_farm.target_area = "sky_farm"
	to_farm.target_floor = 0
	to_farm.custom_label = "返回浮岛农场"
	to_farm.position = Vector2(320, 360)
	entities_root.add_child(to_farm)

func _build_meadow() -> void:
	for i in 6:
		var r = ResourceNodeScript.new()
		r.resource_id = ["fiber", "wood", "stone"][i % 3]
		r.position = Vector2(220 + i * 120, 320)
		entities_root.add_child(r)

func _build_wild() -> void:
	for i in 6:
		var r = ResourceNodeScript.new()
		r.resource_id = "fiber" if i % 2 == 0 else "wind_shard"
		r.position = Vector2(250 + i * 110, 340)
		entities_root.add_child(r)
	var chest = ChestScript.new()
	chest.position = Vector2(980, 260)
	entities_root.add_child(chest)

func _build_cliff() -> void:
	var chest = ChestScript.new()
	chest.position = Vector2(720, 280)
	entities_root.add_child(chest)
	# 风蚀迷宫入口
	var PortalScript = preload("res://scripts/entities/area_portal.gd")
	var maze = PortalScript.new()
	maze.target_area = "maze"
	maze.target_floor = 0
	maze.custom_label = "踏入风蚀迷宫"
	maze.position = Vector2(200, 200)
	entities_root.add_child(maze)
	var r = ResourceNodeScript.new()
	r.resource_id = "mythril_shard"
	r.position = Vector2(520, 360)
	entities_root.add_child(r)
	var r2 = ResourceNodeScript.new()
	r2.resource_id = "wind_shard"
	r2.position = Vector2(560, 320)
	entities_root.add_child(r2)

func _build_pasture() -> void:
	var PenScript = preload("res://scripts/entities/animal_pen.gd")
	var pen = PenScript.new()
	pen.position = Vector2(520, 320)
	entities_root.add_child(pen)
	for i in 4:
		var r = ResourceNodeScript.new()
		r.resource_id = "fiber"
		r.position = Vector2(260 + i * 100, 480)
		entities_root.add_child(r)

func _build_mine_camp() -> void:
	var gate = PortalScript.new()
	gate.target_area = "mine"
	gate.target_floor = 0
	gate.display_name = "进入雾晶矿洞"
	gate.position = Vector2(720, 300)
	entities_root.add_child(gate)

func _build_lakeside() -> void:
	for p in [Vector2(400, 300), Vector2(520, 260), Vector2(640, 320)]:
		var fish = FishSpotScript.new()
		fish.position = p
		entities_root.add_child(fish)
	for p in [Vector2(300, 480), Vector2(380, 520), Vector2(260, 540)]:
		var r = ResourceNodeScript.new()
		r.resource_id = "fiber"
		r.position = p
		entities_root.add_child(r)
	var chest = ChestScript.new()
	chest.position = Vector2(900, 280)
	entities_root.add_child(chest)
	# 小船去湖心岛标记
	var boat = PortalScript.new()
	boat.target_area = "lakeside"
	boat.target_floor = 0
	boat.display_name = "小船（湖心岛待扩展）"
	boat.position = Vector2(720, 400)
	entities_root.add_child(boat)

func _build_forest() -> void:
	for i in 8:
		var r = ResourceNodeScript.new()
		r.resource_id = "wood" if i % 2 == 0 else "fiber"
		r.position = Vector2(250 + (i % 4) * 120, 280 + (i / 4) * 140)
		entities_root.add_child(r)
	var chest = ChestScript.new()
	chest.position = Vector2(1000, 250)
	entities_root.add_child(chest)
	# 风车
	for pos in [Vector2(500, 180), Vector2(860, 220)]:
		var bell_spot = ResourceNodeScript.new()
		bell_spot.resource_id = "wind_shard"
		bell_spot.position = pos
		entities_root.add_child(bell_spot)

func _build_festival() -> void:
	# 终局：铃串装饰 + 庆祝对话
	for id in ["grandpa_lin", "xiaoman", "zhi_tao"]:
		var npc = NpcScript.new()
		npc.npc_id = id
		var base: Dictionary = NpcDb.get_npc(id).get("position", {"x": 400, "y": 300})
		npc.position = Vector2(float(base.x) * 0.6 + 300, 300 + randf() * 80)
		entities_root.add_child(npc)
	var chest = ChestScript.new()
	chest.position = Vector2(700, 360)
	entities_root.add_child(chest)

func _process(_delta: float) -> void:
	_update_hint()

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
	for e in entities_root.get_children():
		if e.has_method("interact") and e.has_method("prompt"):
			var d: float = pp.distance_to(e.global_position)
			var radius: float = 48.0
			if d <= radius and d < best["dist"]:
				best = {"kind": "entity", "target": e, "prompt": e.prompt(), "dist": d}
	return best

func try_interact() -> void:
	var info := get_focus_info()
	var target = info.get("target")
	if target:
		target.interact(player)

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("use_tool"):
		try_interact()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var pal: Dictionary = _palette.get(area_id, _palette["lakeside"])
	draw_rect(Rect2(-80, -40, 1360, 800), pal.ground)
	if area_id == "lakeside":
		draw_circle(Vector2(700, 360), 180.0, Color("#6BA3C8"))
		draw_circle(Vector2(700, 360), 160.0, Color("#8FC0D8"))
		draw_rect(Rect2(200, 380, 80, 24), Color("#C4A574"))
	elif area_id == "forest":
		for i in 10:
			var x := 150.0 + i * 100.0
			draw_circle(Vector2(x, 200 + (i % 3) * 40), 36.0, pal.accent.darkened(0.1))
			draw_rect(Rect2(x - 6, 220, 12, 40), Color("#6B5340"))
		# 风车
		draw_circle(Vector2(500, 160), 28.0, Color("#E8D4B0"))
		draw_line(Vector2(500, 160), Vector2(500, 120), Color("#B08968"), 4.0)
	else:
		for i in 12:
			draw_circle(Vector2(120 + i * 90, 140 + (i % 4) * 20), 8.0, Color("#E8C87A"))
		draw_string(ThemeDB.fallback_font, Vector2(240, 100), "风铃节", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#3D2B1F"))
	draw_string(ThemeDB.fallback_font, Vector2(24, 40),
		"%s · %s" % [str(pal.name), str(pal.desc)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#F3EAD3"))
