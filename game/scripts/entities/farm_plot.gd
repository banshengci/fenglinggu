extends Node2D
class_name FarmPlot
## 单格农田：未耕 / 已耕 / 作物阶段 / 浇水

enum State { GRASS, TILLED, PLANTED }

const TILE := 36

var grid := Vector2i.ZERO
var state: int = State.GRASS
var watered := false
var crop_id := ""
var growth_days := 0
var regrow_left := 0
var ready_to_harvest := false
var flash_quality := false
	## 浮岛温室：可反季种植
	var allow_any_season := false
	var _crop_tex: Texture2D = null  ## 保留字段兼容旧存档/外部引用；当前绘制走 _crop_texture_for()

signal interacted(plot: FarmPlot)

func _ready() -> void:
	add_to_group("daily_tick")
	add_to_group("farm_plots")
	queue_redraw()

func on_new_day() -> void:
	# 先用「昨天是否浇水」结算生长，再清空浇水
	advance_growth()
	watered = false
	queue_redraw()

## 由 World 在跨天时调用（在清空浇水标记前）
func _is_resonant() -> bool:
	return bool(GameState.resonant_plots.get("%d,%d" % [grid.x, grid.y], false))

func advance_growth() -> void:
	if state != State.PLANTED or crop_id == "":
		return
	if not watered:
		return
	var weather_bonus := float(RanchWeather.weather_effects().get("grow_bonus", 0.0))
	if randf() < weather_bonus:
		growth_days += 1  # 好天气额外促生长
	if _is_resonant() and randf() < 0.35:
		growth_days += 1  # 共鸣格促生长
	var data := CropDb.get_crop(crop_id)
	if ready_to_harvest:
		# 再生作物倒计时
		if regrow_left > 0:
			regrow_left -= 1
			if regrow_left <= 0:
				ready_to_harvest = true
		return
	growth_days += 1
	var need := CropDb.get_days_to_grow(crop_id)
	if growth_days >= need:
		ready_to_harvest = true
		# 闪光果：共鸣格 / 风铃附近时概率提升
		if randf() < _flash_chance():
			flash_quality = true

func _flash_chance() -> float:
	var base := 0.05 + 0.01 * RanchWeather.skill_level("farming")
	if _is_resonant():
		base += 0.18
	if GameState.get_flag("tiny_bell_nearby", false) or GameState.get_flag("tiny_bell_placed", false):
		base += 0.15
	return base

func try_till() -> bool:
	if state != State.GRASS:
		return false
	state = State.TILLED
	Sfx.play("till")
	QuestLog.mark("till")
	queue_redraw()
	return true

func try_plant(crop: String) -> bool:
	if state != State.TILLED or crop_id != "":
		return false
	if not allow_any_season and not CropDb.can_plant_in_season(crop, TimeSystem.season()):
		EventBus.toast.emit("%s 不适合在 %s 种植" % [CropDb.crop_name(crop), TimeSystem.season()])
		return false
	state = State.PLANTED
	crop_id = crop
	growth_days = 0
	regrow_left = 0
	ready_to_harvest = false
	flash_quality = false
	watered = false
	Sfx.play("click")
	QuestLog.mark("plant")
	queue_redraw()
	return true

func try_water() -> bool:
	if state == State.GRASS:
		return false
	if watered:
		return false
	watered = true
	Sfx.play("water")
	QuestLog.mark("water")
	queue_redraw()
	return true

func try_harvest() -> bool:
	if state != State.PLANTED or not ready_to_harvest:
		return false
	var product := CropDb.get_product_item(crop_id)
	var count := 2 if flash_quality else 1
	# 土豆等有概率多收
	if crop_id == "potato" and randf() < 0.25:
		count += 1
	Inventory.add_item(product, count)
	Sfx.play("harvest", 1.15 if flash_quality else 1.0)
	QuestLog.mark("harvest")
	Achievements.add_stat("harvest_count", count)
	MuseumDb.mark_discover(product)
	RanchWeather.add_exp("farming", 2)
	if flash_quality:
		Achievements.add_stat("flash_count", 1)
		EventBus.toast.emit("闪光收获！%s ×%d" % [ItemDb.item_name(product), count])
	# 共鸣田吸引蝴蝶
	if _is_resonant() and randf() < 0.12:
		MuseumDb.mark_butterfly()
	# 风铃碎片小概率
	if randf() < 0.04:
		Inventory.add_item("wind_shard", 1)
		GameState.wind_shards += 1
		EventBus.toast.emit("捡到风铃碎片！")
	var regrow := CropDb.get_regrow_days(crop_id)
	if regrow > 0:
		ready_to_harvest = false
		growth_days = CropDb.get_days_to_grow(crop_id) - regrow
		regrow_left = 0
		flash_quality = false
	else:
		_reset_to_tilled()
	queue_redraw()
	EventBus.crop_state_changed.emit()
	return true

func try_clear() -> bool:
	## 移除作物或恢复草地
	if state == State.PLANTED:
		_reset_to_tilled()
		queue_redraw()
		return true
	if state == State.TILLED:
		state = State.GRASS
		queue_redraw()
		return true
	return false

func _reset_to_tilled() -> void:
	state = State.TILLED
	crop_id = ""
	growth_days = 0
	regrow_left = 0
	ready_to_harvest = false
	flash_quality = false

func stage_index() -> int:
	if crop_id == "" or state != State.PLANTED:
		return 0
	if ready_to_harvest:
		return CropDb.get_stages(crop_id) - 1
	var need: int = max(1, CropDb.get_days_to_grow(crop_id))
	var stages: int = CropDb.get_stages(crop_id)
	var t := clampf(float(growth_days) / float(need), 0.0, 0.99)
	return clampi(int(t * (stages - 1)), 0, stages - 2)

func description() -> String:
	match state:
		State.GRASS:
			return "荒地（E：锄地）"
		State.TILLED:
			return "已耕作（E：播种 / 选中种子后）"
		State.PLANTED:
			if ready_to_harvest:
				return "%s 可收获（E）" % CropDb.crop_name(crop_id)
			var tip := "已浇水" if watered else "需要浇水"
			return "%s · 第 %d/%d 天 · %s" % [
				CropDb.crop_name(crop_id),
				growth_days,
				CropDb.get_days_to_grow(crop_id),
				tip,
			]
	return ""

func to_dict() -> Dictionary:
	return {
		"grid": [grid.x, grid.y],
		"state": state,
		"watered": watered,
		"crop_id": crop_id,
		"growth_days": growth_days,
		"regrow_left": regrow_left,
		"ready": ready_to_harvest,
		"flash": flash_quality,
	}

func from_dict(d: Dictionary) -> void:
	state = int(d.get("state", 0))
	watered = bool(d.get("watered", false))
	crop_id = str(d.get("crop_id", ""))
	growth_days = int(d.get("growth_days", 0))
	regrow_left = int(d.get("regrow_left", 0))
	ready_to_harvest = bool(d.get("ready", false))
	flash_quality = bool(d.get("flash", false))
	queue_redraw()

## 按 (作物 id, 生长阶段) 取美术图；走 ArtPipeline 统一命名约定。
## 找不到对应阶段的图时逐级回退到更早阶段 / 无阶段图，取不到返回 null
## 由 _draw() 继续走程序化绘制。1x1 占位图（sprites/ 下的旧 stub）一律忽略。
func _crop_texture_for(stage: int) -> Texture2D:
	if crop_id == "":
		return null
	var s := stage
	while s >= 0:
		var t := ArtPipeline.crop(crop_id, s)
		if t != null and t.get_width() >= 8 and t.get_height() >= 8:
			return t
		s -= 1
	var t0 := ArtPipeline.crop(crop_id, -1)
	if t0 != null and t0.get_width() >= 8 and t0.get_height() >= 8:
		return t0
	return null

func _draw() -> void:
	var r := Rect2(-TILE * 0.5, -TILE * 0.5, TILE, TILE)
	# 底土
	var ground := Color("#6B8F5A")
	if state == State.TILLED or state == State.PLANTED:
		ground = Color("#5C4030") if not watered else Color("#3E2A1E")
	draw_rect(r, ground)
	# 边框
	draw_rect(r, Color("#2F3D28"), false, 1.0)
	# 作物
	if state == State.PLANTED and crop_id != "":
		var stage := stage_index()
		var crop_tex := _crop_texture_for(stage)
		if crop_tex != null:
			var mod := Color(1.35, 1.35, 1.15) if (ready_to_harvest and flash_quality) else Color.WHITE
			draw_texture_rect(crop_tex, Rect2(-10, -16, 20, 20), false, mod)
			if ready_to_harvest:
				var fx := ArtPipeline.tex("fx_harvest")
				if fx:
					draw_texture_rect(fx, Rect2(-12, -20, 24, 24), false)
				else:
					draw_circle(Vector2(0, -8), 3.0, Color("#FFF2A8"))
		else:
			var stages: int = CropDb.get_stages(crop_id)
			var col: Color
			if ready_to_harvest:
				col = CropDb.get_mature_color(crop_id)
			else:
				col = CropDb.get_sprout_color(crop_id).lerp(CropDb.get_mature_color(crop_id), float(stage) / maxf(1.0, stages - 1.0))
			if flash_quality:
				col = col.lightened(0.35)
			var h := 6.0 + stage * 4.0
			draw_circle(Vector2(0, 4 - h * 0.2), 4.0 + stage * 1.5, col)
			draw_circle(Vector2(-5, 2), 3.0 + stage, col.darkened(0.1))
			draw_circle(Vector2(5, 2), 3.0 + stage, col.darkened(0.1))
			if ready_to_harvest:
				var fx := ArtPipeline.tex("fx_harvest")
				if fx:
					draw_texture_rect(fx, Rect2(-12, -20, 24, 24), false)
				else:
					draw_circle(Vector2(0, -8), 3.0, Color("#FFF2A8"))
	# 浇水标记
	if watered and state != State.GRASS:
		draw_circle(Vector2(TILE * 0.5 - 5, -TILE * 0.5 + 5), 3.0, Color("#7EC8E3"))
