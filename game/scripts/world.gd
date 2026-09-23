extends Node2D
## 主世界：灰盒地图、菜园、实体、交互查找、存档收集

const PLOT_SIZE := 36
const FARM_ORIGIN := Vector2(220, 420)
const FARM_W := 6
const FARM_H := 4

var player: CharacterBody2D
var plots: Array = []
var plots_root: Node2D
var entities_root: Node2D

func _ready() -> void:
	add_to_group("save_serializable")
	if player == null:
		player = get_node_or_null("Player")
	plots_root = get_node_or_null("Plots") as Node2D
	entities_root = get_node_or_null("Entities") as Node2D
	if plots_root == null:
		plots_root = Node2D.new()
		plots_root.name = "Plots"
		add_child(plots_root)
	if entities_root == null:
		entities_root = Node2D.new()
		entities_root.name = "Entities"
		add_child(entities_root)
	_build_farm()
	_build_entities()
	queue_redraw()

func _build_farm() -> void:
	const FarmPlotScript := preload("res://scripts/entities/farm_plot.gd")
	for y in FARM_H:
		for x in FARM_W:
			var p = FarmPlotScript.new()
			p.grid = Vector2i(x, y)
			p.position = FARM_ORIGIN + Vector2(x * PLOT_SIZE, y * PLOT_SIZE)
			plots_root.add_child(p)
			plots.append(p)

func _build_entities() -> void:
	const ShippingBinScript := preload("res://scripts/entities/shipping_bin.gd")
	const WorkbenchScript := preload("res://scripts/entities/workbench.gd")
	const NpcScript := preload("res://scripts/entities/npc.gd")
	const ResourceNodeScript := preload("res://scripts/entities/resource_node.gd")
	const BedScript := preload("res://scripts/entities/bed.gd")
	const WindBellTowerScript := preload("res://scripts/entities/wind_bell_tower.gd")
	const PortalScript := preload("res://scripts/entities/area_portal.gd")
	const SeedShopScript := preload("res://scripts/entities/seed_shop.gd")
	const FurnitureSpotScript := preload("res://scripts/entities/furniture_spot.gd")
	const CommissionBoardScript := preload("res://scripts/entities/commission_board.gd")
	const MuseumScript := preload("res://scripts/entities/museum_building.gd")
	const PadScript := preload("res://scripts/entities/furniture_pad.gd")
	const ShrineScript := preload("res://scripts/entities/wind_shrine.gd")

	var bin = ShippingBinScript.new()
	bin.position = Vector2(180, 300)
	entities_root.add_child(bin)

	var bench = WorkbenchScript.new()
	bench.position = Vector2(320, 280)
	bench.station = "workbench"
	entities_root.add_child(bench)

	var kitchen = WorkbenchScript.new()
	kitchen.position = Vector2(380, 280)
	kitchen.station = "kitchen"
	entities_root.add_child(kitchen)

	var carpentry = WorkbenchScript.new()
	carpentry.position = Vector2(350, 320)
	carpentry.station = "carpentry"
	entities_root.add_child(carpentry)

	var forge = WorkbenchScript.new()
	forge.position = Vector2(300, 320)
	forge.station = "forge"
	entities_root.add_child(forge)

	var atelier = WorkbenchScript.new()
	atelier.position = Vector2(250, 320)
	atelier.station = "crystal_atelier"
	entities_root.add_child(atelier)

	var bed = BedScript.new()
	bed.position = Vector2(250, 180)
	entities_root.add_child(bed)

	var tower = WindBellTowerScript.new()
	tower.position = Vector2(640, 200)
	entities_root.add_child(tower)

	var shop = SeedShopScript.new()
	shop.position = Vector2(480, 240)
	entities_root.add_child(shop)

	var decor_spot = FurnitureSpotScript.new()
	decor_spot.position = Vector2(200, 400)
	entities_root.add_child(decor_spot)

	var mine_gate = PortalScript.new()
	mine_gate.target_area = "mine"
	mine_gate.target_floor = 0
	mine_gate.position = Vector2(1100, 250)
	mine_gate.display_name = "雾晶矿洞入口"
	entities_root.add_child(mine_gate)

	var board = CommissionBoardScript.new()
	board.position = Vector2(560, 260)
	entities_root.add_child(board)

	var museum = MuseumScript.new()
	museum.position = Vector2(420, 160)
	entities_root.add_child(museum)

	var shrine = ShrineScript.new()
	shrine.area_id = "town"
	shrine.position = Vector2(600, 320)
	entities_root.add_child(shrine)
	# 热气球：空中航线 → 浮岛农场
	var balloon = PortalScript.new()
	balloon.target_area = "sky_farm"
	balloon.target_floor = 0
	balloon.custom_label = "乘热气球登上浮岛"
	balloon.position = Vector2(720, 280)
	entities_root.add_child(balloon)
	# 议事会告示板
	var CouncilScript := preload("res://scripts/entities/council_board.gd")
	var council = CouncilScript.new()
	council.position = Vector2(500, 240)
	entities_root.add_child(council)
	# 联赛奖杯架
	var TrophyScript := preload("res://scripts/entities/trophy_shelf.gd")
	var shelf = TrophyScript.new()
	shelf.position = Vector2(380, 240)
	entities_root.add_child(shelf)

	for i in 4:
		var pad = PadScript.new()
		pad.position = Vector2(360 + i * 50, 390)
		entities_root.add_child(pad)

	var lake_gate = PortalScript.new()
	lake_gate.target_area = "lakeside"
	lake_gate.target_floor = 0
	lake_gate.position = Vector2(1080, 480)
	lake_gate.display_name = "湖畔栈道"
	if not StoryDb.is_area_unlocked("lakeside"):
		lake_gate.set_locked(true, "湖边的雾还没散。先修好风铃吧。")
	entities_root.add_child(lake_gate)

	var forest_gate = PortalScript.new()
	forest_gate.target_area = "forest"
	forest_gate.target_floor = 0
	forest_gate.position = Vector2(140, 160)
	forest_gate.display_name = "旧风车林"
	if not StoryDb.is_area_unlocked("forest"):
		forest_gate.set_locked(true, "林间的小路被藤蔓缠住了。先推进风铃吧。")
	entities_root.add_child(forest_gate)

	var fest_gate = PortalScript.new()
	fest_gate.target_area = "festival"
	fest_gate.target_floor = 0
	fest_gate.position = Vector2(640, 120)
	fest_gate.display_name = "风铃祭广场"
	if not StoryDb.festival_done:
		fest_gate.set_locked(true, "风铃节还没到。五铃齐鸣后再来。")
	entities_root.add_child(fest_gate)

	var deep_gate = PortalScript.new()
	deep_gate.target_area = "deep_mine"
	deep_gate.target_floor = 0
	deep_gate.position = Vector2(1180, 250)
	deep_gate.display_name = "矿脉深部"
	if not StoryDb.is_area_unlocked("deep_mine"):
		deep_gate.set_locked(true, "深部闸门紧闭。需要更强的回响。")
	entities_root.add_child(deep_gate)

	for id in NpcDb.list_ids():
		var npc = NpcScript.new()
		npc.set("npc_id", id)
		var pos: Dictionary = NpcDb.get_npc(id).get("position", {"x": 500, "y": 320})
		npc.position = Vector2(float(pos.get("x", 500)), float(pos.get("y", 320)))
		entities_root.add_child(npc)

	var resource_spots := [
		["wood", Vector2(140, 220)], ["wood", Vector2(170, 240)], ["wood", Vector2(120, 250)],
		["stone", Vector2(900, 480)], ["stone", Vector2(940, 500)], ["stone", Vector2(880, 520)],
		["fiber", Vector2(480, 500)], ["fiber", Vector2(520, 520)], ["fiber", Vector2(560, 500)],
		["wood", Vector2(1000, 220)], ["stone", Vector2(200, 520)],
	]
	for res_entry in resource_spots:
		var node = ResourceNodeScript.new()
		node.set("resource_id", res_entry[0])
		node.position = res_entry[1]
		entities_root.add_child(node)

func _process(_delta: float) -> void:
	_update_hint()
	_update_bell_bonus()

func _update_bell_bonus() -> void:
	# 共鸣田园：风铃/晶灯家具形成 3×3 共鸣格，加速同族作物并提升闪光率
	var has_bell := false
	var resonant := {}
	if entities_root:
		for e in entities_root.get_children():
			var fid: String = ""
			if e.has_method("get"):
				var raw = e.get("placed_id")
				if raw != null:
					fid = str(raw)
			if fid in ["tiny_bell", "hanging_bells", "bell_mobile", "crystal_lamp", "lantern"]:
				has_bell = true
				# 以家具为中心覆盖 3×3 农田格
				var center: Vector2 = e.global_position
				for p in plots:
					if p.global_position.distance_to(center) <= float(PLOT_SIZE) * 2.2:
						resonant["%d,%d" % [p.grid.x, p.grid.y]] = true
	GameState.bell_bonus = has_bell
	GameState.resonant_plots = resonant

func _update_hint() -> void:
	var hint_node := get_node_or_null("../../UI/HUD")
	if hint_node == null:
		hint_node = get_node_or_null("../UI/HUD")
	if hint_node == null or not hint_node.has_method("set_hint"):
		return
	var info := get_focus_info()
	hint_node.set_hint(info.get("prompt", ""))

## 返回最近交互目标信息 {kind, target, prompt}
func get_focus_info() -> Dictionary:
	var pp: Vector2 = player.global_position
	var best := {"kind": "", "target": null, "prompt": "", "dist": 1e9}

	for p in plots:
		var d: float = pp.distance_to(p.global_position)
		if d < 48.0 and d < best["dist"]:
			best = {
				"kind": "plot",
				"target": p,
				"prompt": "E：%s" % p.description(),
				"dist": d,
			}

	for e in entities_root.get_children():
		if e.has_method("interact") and e.has_method("prompt"):
			var d2: float = pp.distance_to(e.global_position)
			var radius: float = float(e.get("interact_radius")) if e.get("interact_radius") != null else 42.0
			if d2 <= radius and d2 < best["dist"]:
				best = {
					"kind": "entity",
					"target": e,
					"prompt": e.prompt(),
					"dist": d2,
				}
	return best

func _current_item() -> String:
	var ui := get_tree().get_first_node_in_group("inventory_ui")
	if ui and ui.has_method("selected_item_id"):
		var id: String = ui.selected_item_id()
		return id
	return ""

func _try_interact_plot(plot) -> void:
	var held := _current_item()
	if plot.state == 2 and plot.ready_to_harvest:  # State.PLANTED
		plot.try_harvest()
		return
	if held != "" and ItemDb.is_tool(held):
		match ItemDb.get_tool_action(held):
			"till":
				if plot.try_till():
					EventBus.toast.emit("锄地完成")
				else:
					EventBus.toast.emit("无法锄地")
				return
			"water":
				if plot.try_water():
					EventBus.toast.emit("浇水完成")
					EventBus.crop_state_changed.emit()
				elif plot.state == 0:
					EventBus.toast.emit("这里还没耕作")
				else:
					EventBus.toast.emit("今天已经浇过水了")
				return
			"chop", "mine":
				if plot.try_clear():
					EventBus.toast.emit("清除了地上的东西")
				return
	if held != "" and ItemDb.is_seed(held):
		var crop := ItemDb.get_crop_id(held)
		if plot.try_plant(crop):
			Inventory.remove_item(held, 1)
			EventBus.toast.emit("种下了 %s" % CropDb.crop_name(crop))
			EventBus.crop_state_changed.emit()
		return
	# 右键思路的替代：若工具为水壶逻辑已覆盖
	if plot.state == 0:
		EventBus.toast.emit("选中锄头后按 E 翻地")
	elif plot.state == 1:
		EventBus.toast.emit("选中种子后按 E 播种")
	else:
		EventBus.toast.emit("选中水壶后按 E 浇水")

func try_interact() -> void:
	var info := get_focus_info()
	var target = info.get("target")
	if target == null:
		return
	if info["kind"] == "plot":
		_try_interact_plot(target)
	elif info["kind"] == "entity":
		target.interact(player)

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("use_tool"):
		try_interact()
		get_viewport().set_input_as_handled()

func on_save_collect() -> void:
	var farm: Array = []
	for p in plots:
		farm.append(p.to_dict())
	GameState.farm_state = farm
	var pads: Array = []
	if entities_root:
		for e in entities_root.get_children():
			if e.has_method("to_dict") and e.get("placed_id") != null:
				pads.append(e.to_dict())
	GameState.flags["furniture_pads"] = pads

func on_save_restore() -> void:
	if GameState.farm_state.size() == plots.size():
		for i in plots.size():
			plots[i].from_dict(GameState.farm_state[i])
	var pads: Array = GameState.flags.get("furniture_pads", [])
	var pad_nodes: Array = []
	if entities_root:
		for e in entities_root.get_children():
			if e.has_method("from_dict") and e.get("placed_id") != null:
				pad_nodes.append(e)
	for i in mini(pad_nodes.size(), pads.size()):
		pad_nodes[i].from_dict(pads[i])
	for e in entities_root.get_children():
		if e.has_method("on_save_restore"):
			e.on_save_restore()
	EventBus.crop_state_changed.emit()

func _draw() -> void:
	# 田园底色：有 tile 则铺贴图
	var grass := ArtPipeline.tex("tile_grass")
	if grass:
		var x := -80.0
		while x < 1280:
			var y := -40.0
			while y < 760:
				draw_texture_rect(grass, Rect2(x, y, 32, 32), false)
				y += 32
			x += 32
	else:
		draw_rect(Rect2(-80, -40, 1360, 800), Color("#8FB56F"))
	# 天气叠色
	# 天气叠色（性能档可关）
	if not GameState.get_flag("low_fx", false):
		match RanchWeather.weather:
			"细雨":
				draw_rect(Rect2(-80, -40, 1360, 800), Color(0.5, 0.6, 0.7, 0.18))
			"雾":
				draw_rect(Rect2(-80, -40, 1360, 800), Color(0.8, 0.8, 0.85, 0.28))
			"小雪":
				draw_rect(Rect2(-80, -40, 1360, 800), Color(0.9, 0.9, 1.0, 0.22))
			"风暴前夜":
				draw_rect(Rect2(-80, -40, 1360, 800), Color(0.3, 0.3, 0.45, 0.25))
			"多云":
				draw_rect(Rect2(-80, -40, 1360, 800), Color(0.7, 0.7, 0.7, 0.12))
	# 草地斑块
	for i in 18:
		var x := 40.0 + i * 70.0
		var y := 620.0 + sin(i * 0.7) * 40.0
		draw_circle(Vector2(x, y), 28.0, Color("#7FA36A"))
	# 小路
	var path := ArtPipeline.tex("tile_path")
	if path:
		for i in 10:
			draw_texture_rect(path, Rect2(160, 250 + i * 33, 44, 33), false)
		for i in 7:
			draw_texture_rect(path, Rect2(160 + i * 33, 250, 33, 40), false)
	else:
		draw_rect(Rect2(160, 250, 44, 330), Color("#D2B48C"))
		draw_rect(Rect2(160, 250, 230, 40), Color("#D2B48C"))
		draw_rect(Rect2(600, 160, 90, 44), Color("#D2B48C"))
		draw_rect(Rect2(1020, 230, 80, 40), Color("#D2B48C"))
	# 杂货摊
	var shop := ArtPipeline.building("shop")
	if shop:
		draw_texture_rect(shop, Rect2(460, 220, 80, 50), false)
	# 水池
	draw_circle(Vector2(1050, 380), 56.0, Color("#5A90B8"))
	draw_circle(Vector2(1050, 380), 48.0, Color("#8FC0D8"))
	draw_circle(Vector2(1035, 365), 10.0, Color(1, 1, 1, 0.25))
	# 屋舍：优先贴图
	var house := ArtPipeline.building("house")
	if house:
		draw_texture_rect(house, Rect2(190, 120, 110, 80), false)
	else:
		draw_rect(Rect2(200, 130, 90, 60), Color("#E8D4B0"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(190, 132), Vector2(245, 100), Vector2(300, 132)
		]), Color("#B08968"))
		draw_rect(Rect2(235, 150, 22, 40), Color("#6B5340"))
	# 风铃塔
	var tower := ArtPipeline.building("belltower")
	if tower:
		draw_texture_rect(tower, Rect2(610, 120, 60, 100), false)
	else:
		draw_rect(Rect2(628, 150, 24, 70), Color("#A8B8C0"))
		draw_circle(Vector2(640, 140), 12.0, Color("#E8C87A"))
	# 栅栏示意
	for i in 8:
		draw_rect(Rect2(220 + i * 36, 400, 4, 18), Color("#C4A574"))
	# 风铃塔柱
	draw_rect(Rect2(628, 150, 24, 70), Color("#A8B8C0"))
	draw_circle(Vector2(640, 140), 12.0, Color("#E8C87A"))
	# 标题牌
	draw_rect(Rect2(12, 12, 360, 34), Color(0.2, 0.18, 0.12, 0.35))
	draw_string(ThemeDB.fallback_font, Vector2(24, 36),
		"翠谷镇  ·  种田 | 矿洞在东侧 | 杂货摊可买种子",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#F3EAD3"))
