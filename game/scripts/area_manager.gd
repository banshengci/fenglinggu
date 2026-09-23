extends Node
## 区域与矿洞管理：镇 ↔ 各户外区 ↔ 矿洞楼层

const TownWorldScript := preload("res://scripts/world.gd")
const MineLevelScript := preload("res://scripts/mine_level.gd")
const MazeLevelScript := preload("res://scripts/maze_level.gd")
const OverworldScript := preload("res://scripts/overworld_area.gd")
const PlayerScript := preload("res://scripts/player.gd")

var host: Node2D
var player: CharacterBody2D
var current_area := "town"
var current_floor := 0
var mine_session: Dictionary = {}
var player_hp := 5
var max_hp := 5
var current_level: Node2D

func _ready() -> void:
	add_to_group("area_manager")
	add_to_group("save_serializable")
	host = Node2D.new()
	host.name = "Host"
	add_child(host)

	player = CharacterBody2D.new()
	player.name = "Player"
	player.set_script(PlayerScript)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18, 22)
	col.shape = shape
	player.add_child(col)
	# 跟随相机：走出屏幕时视野随人走，地图可继续扩
	var cam := Camera2D.new()
	cam.name = "PlayerCam"
	cam.enabled = true
	cam.make_current()
	cam.zoom = Vector2(1.0, 1.0)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	player.add_child(cam)
	add_child(player)
	player.position = Vector2(300, 360)

	travel_to("town", 0, true)

func is_area_unlocked(area: String) -> bool:
	if area == "town" or area == "mine":
		return true
	if area == "maze":
		return is_area_unlocked("cliff_top") or StoryDb.bells_repaired >= 3
	if WorldMapDb.data.size() > 0 and not WorldMapDb.region(area).is_empty():
		return WorldMapDb.is_unlocked(area)
	return area in StoryDb.unlocked_areas()

func travel_to(area: String, floor_idx: int = 0, silent: bool = false) -> void:
	if not is_area_unlocked(area) and area not in ["town", "mine"]:
		EventBus.dialogue_started.emit(["那里还去不了。先把风铃修起来吧。"], "system")
		return
	for c in host.get_children():
		c.queue_free()
	current_area = area
	current_floor = maxi(floor_idx, 0)
	if area == "mine":
		Achievements.set_stat("max_floor", current_floor + 1)
	if area == "deep_mine":
		Achievements.set_stat("max_floor", 4 + current_floor)
	match area:
		"town":
			current_level = TownWorldScript.new()
			current_level.player = player
			host.add_child(current_level)
			player.position = Vector2(300, 360)
		"mine":
			current_level = MineLevelScript.new()
			current_level.floor_index = current_floor
			current_level.mine_session = mine_session
			current_level.player = player
			host.add_child(current_level)
			player.position = Vector2(120, 400)
		"deep_mine":
			current_level = MineLevelScript.new()
			# 深部从 B4 起（索引 3）
			current_level.floor_index = 3 + current_floor
			current_level.mine_session = mine_session
			current_level.player = player
			host.add_child(current_level)
			player.position = Vector2(120, 400)
		"maze":
			current_level = MazeLevelScript.new()
			current_level.floor_index = current_floor
			current_level.maze_session = mine_session
			current_level.player = player
			host.add_child(current_level)
			player.position = Vector2(120, 400)
		"lakeside", "forest", "festival", "farm_valley", "wild_woods", "cliff_top", "pasture", "mine_camp", "plaza", "sky_farm", "sky_cliff":
			current_level = OverworldScript.new()
			current_level.area_id = area
			current_level.player = player
			host.add_child(current_level)
			player.position = Vector2(160, 400)
		_:
			if WorldMapDb.region(area).size() > 0:
				current_level = OverworldScript.new()
				current_level.area_id = area
				current_level.player = player
				host.add_child(current_level)
				player.position = Vector2(160, 400)
			else:
				current_level = TownWorldScript.new()
				current_level.player = player
			host.add_child(current_level)
			player.position = Vector2(300, 360)
	player.set_meta("iframe", 0.0)
	player.modulate = Color.WHITE
	if not silent:
		_announce(area)
	EventBus.hud_refresh.emit()
	Bgm.refresh_from_time()

func _announce(area: String) -> void:
	match area:
		"town":
			EventBus.toast.emit("回到翠谷镇")
		"lakeside":
			EventBus.toast.emit("湖畔栈道")
			EventBus.dialogue_started.emit(["湖面很静，小船在轻轻碰岸。"], "system")
		"forest":
			EventBus.toast.emit("旧风车林")
			EventBus.dialogue_started.emit(["风车吱呀，树影里藏着旧约。"], "system")
		"festival":
			EventBus.toast.emit("风铃祭广场")
			EventBus.dialogue_started.emit(["彩绳与铃铛把整个广场挂满了声音。"], "system")
		"deep_mine":
			EventBus.toast.emit("矿脉深部")
			EventBus.dialogue_started.emit(["空气里有金属和旧歌的味道。"], "system")
		_:
			var fl := MineDb.get_floor(current_floor)
			EventBus.toast.emit(str(fl.get("name", "矿洞")))
			if str(fl.get("desc", "")) != "":
				EventBus.dialogue_started.emit([str(fl.get("desc"))], "system")

func set_hp(v: int) -> void:
	player_hp = clampi(v, 0, max_hp)
	EventBus.hud_refresh.emit()
	if player_hp <= 0:
		_faint()

func damage_player(n: int = 1) -> void:
	if player_hp <= 0:
		return
	set_hp(player_hp - n)
	Sfx.play("hurt")
	EventBus.toast.emit("受伤了！（HP %d/%d）" % [player_hp, max_hp])

func _faint() -> void:
	EventBus.toast.emit("你眼前一黑……醒来时已在矿洞入口。")
	mine_session.clear()
	if current_area == "mine" or current_area == "deep_mine":
		travel_to("mine", 0, true)
	else:
		travel_to("town", 0, true)
	set_hp(max_hp)

func heal_full() -> void:
	set_hp(max_hp)

func on_save_collect() -> void:
	GameState.add_flag("player_hp", player_hp)
	GameState.add_flag("last_area", current_area)
	GameState.add_flag("last_floor", current_floor)

func on_save_restore() -> void:
	player_hp = int(GameState.get_flag("player_hp", max_hp))
	if player_hp <= 0:
		player_hp = max_hp
