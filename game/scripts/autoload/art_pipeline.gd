extends Node
## 美术管线：把数据层 id 解析到 workbuddy 交付的美术文件，缺图回退 null（程序化绘制）。
##
## 解析顺序（两路，先准后宽）：
##   1) 显式映射表 ArtIdMap（297 条，由 docs/art/art_id_map.json 生成）—— 数据层 id 与
##      美术文件名并不同名（例如 fish id `carp_spring` -> 文件 `fish_brook_carp.png`），
##      所以必须查表，不能靠字符串拼接。
##   2) 命名约定回退：在 CANDIDATE_ROOTS 下按 key 拼 .png 逐个试。
##
## 两条路都取不到时返回 null，调用方应保留程序化绘制兜底。

const ArtIdMap := preload("res://scripts/autoload/art_id_map.gd")

const CANDIDATE_ROOTS := [
	"res://art/chars/walk/",
	"res://art/chars/",
	"res://art/crops/",
	"res://art/tiles/",
	"res://art/buildings/",
	"res://art/items/",
	"res://art/furniture/",
	"res://art/enemies/",
	"res://art/animals/",
	"res://art/ui/",
	"res://art/fx/",
	"res://art/cutscenes/",
	"res://art/marketing/",
	"res://art/sprites/",
	"res://art/keys/",
]

## 道具图标的美术文件名前缀，按命中优先级排列。
## 数据层一个 id 可能落在 dish/fish/relic/seed 任一类里，逐个试。
const ICON_PREFIXES := ["dish_", "fish_", "relic_", "seed_", "icon_"]

## 3 种矿岩没有独立贴图，用已有贴图 + 色相调制顶上（见 ore_tint()）。
const ORE_ALIAS := {
	"silver_ore": "iron_ore",
	"gold_ore": "copper_ore",
	"mythril_shard": "crystal",
}

var _cache: Dictionary = {}


func tex(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var t := _try_load(key)
	_cache[key] = t
	return t


## 走显式映射表取图。kind/id 见 docs/art/art_id_map.json。
func mapped(kind: String, id: String) -> Texture2D:
	var rel: String = ArtIdMap.path_of(kind, id)
	if rel == "":
		return null
	return _load_rel(rel)


## 成熟作物图；传 stage>=0 时优先取该生长阶段图，取不到逐级回退到更早阶段。
func crop(crop_id: String, stage: int = -1) -> Texture2D:
	if stage >= 0:
		var s := stage
		while s >= 0:
			var t := mapped("crop_stage", "%s:s%d" % [crop_id, s])
			if t:
				return t
			t = tex("crop_%s_s%d" % [crop_id, s])
			if t:
				return t
			s -= 1
	var t0 := mapped("crop", crop_id)
	if t0:
		return t0
	return tex("crop_%s" % crop_id)


func crop_seed(crop_id: String) -> Texture2D:
	var t := mapped("seed", "seed_" + crop_id)
	if t:
		return t
	return tex("seed_" + crop_id)


## 道具图标：先查映射表，再按前缀逐个试（dish_/fish_/relic_/seed_/icon_）。
func item_icon(item_id: String) -> Texture2D:
	var t := mapped("item_icon", item_id)
	if t:
		return t
	for kind in ["dish", "fish", "antique", "seed"]:
		t = mapped(kind, item_id)
		if t:
			return t
	for p in ICON_PREFIXES:
		t = tex(p + item_id)
		if t:
			return t
	return null


func npc_portrait(npc_id: String) -> Texture2D:
	var t := mapped("npc", npc_id)
	if t:
		return t
	t = tex("npc_" + npc_id)
	if t:
		return t
	return tex("portrait_" + npc_id)


func building(id: String) -> Texture2D:
	return tex("building_" + id)


func furniture(id: String) -> Texture2D:
	var t := mapped("furniture", id)
	if t:
		return t
	return tex("furniture_" + id)


## 矿岩贴图。gold/silver/mythril 三种走复用 + 色相，见 ore_tint()。
func ore_rock(ore_id: String) -> Texture2D:
	var t := mapped("ore_rock", ore_id)
	if t:
		return t
	t = tex("ore_rock_" + ore_id)
	if t:
		return t
	var alias: String = ORE_ALIAS.get(ore_id, "")
	if alias != "":
		return tex("ore_rock_" + alias)
	return null


## 矿岩复用贴图的着色系数：返回 Color.WHITE 表示不需要着色。
func ore_tint(ore_id: String) -> Color:
	match ore_id:
		"gold_ore":
			return Color(1.25, 1.05, 0.55)
		"silver_ore":
			return Color(1.15, 1.18, 1.25)
		"mythril_shard":
			return Color(0.85, 0.95, 1.35)
	return Color.WHITE


## 敌人动画帧，例如 enemy_frame("slime", "walk", 2) -> enemy_slime_walk_02.png
func enemy_frame(enemy_id: String, anim: String, i: int) -> Texture2D:
	var t := mapped("enemy_frame", "%s:%s:%02d" % [enemy_id, anim, i])
	if t:
		return t
	return tex("enemy_%s_%s_%02d" % [enemy_id, anim, i])


## 主角行走帧，dir_name ∈ down/left/right/up，i ∈ 0..3
## 落盘在 art/chars/walk/player_<dir>_<NN>.png（192x288，透明底，脚底对齐）
func player_walk(dir_name: String, i: int) -> Texture2D:
	var t := mapped("player_walk", "%s:%02d" % [dir_name, i])
	if t:
		return t
	return tex("player_%s_%02d" % [dir_name, i])


## NPC 行走帧，npc_id 见 data/npcs.json
## 落盘在 art/chars/walk/npc_<npc_id>_<dir>_<NN>.png
func npc_walk(npc_id: String, dir_name: String, i: int) -> Texture2D:
	var t := mapped("npc_walk", "%s:%s:%02d" % [npc_id, dir_name, i])
	if t:
		return t
	return tex("npc_%s_%s_%02d" % [npc_id, dir_name, i])


func ui(id: String) -> Texture2D:
	return tex("ui_" + id)


## 旧接口（帧号是一位数的老命名），内部统一走 player_walk 的两位帧号。
func player_frame(dir_name: String, i: int) -> Texture2D:
	return player_walk(dir_name, i)


func _load_rel(rel: String) -> Texture2D:
	var path := "res://art/" + rel
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _try_load(key: String) -> Texture2D:
	for root in CANDIDATE_ROOTS:
		var path: String = root + key + ".png"
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


func reload() -> void:
	_cache.clear()
	EventBus.toast.emit("美术已重新扫描")


func stats() -> String:
	var n := 0
	for k in _cache:
		if _cache[k] != null:
			n += 1
	return "art_pipeline 可用图 %d" % n
