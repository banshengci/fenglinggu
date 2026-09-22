extends Node
## 天气与技能 / 畜牧数据

const PATH := "res://data/ranch_weather_skills.json"

var data: Dictionary = {}
var weather := "晴朗"
var skill_exp: Dictionary = {}  # id -> exp
var animals_owned: Dictionary = {}  # animal_id -> count

func _ready() -> void:
	_load()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = parsed

func weather_types() -> Array:
	return data.get("weather_types", ["晴朗"])

func weather_effects() -> Dictionary:
	return data.get("weather_effects", {}).get(weather, {"grow_bonus": 0.0, "fish_bonus": 0.0, "forage_bonus": 0.0})

func roll_weather(season: String) -> void:
	var pool: Array = weather_types().duplicate()
	if season == "静雪冬":
		pool.append("小雪")
	if season == "长夏":
		pool.append("细雨")
	if season == "萌芽春":
		pool.append("细雨")
	weather = str(pool[randi() % pool.size()])

func skills() -> Array:
	return data.get("skills", [])

func add_exp(id: String, n: int) -> void:
	skill_exp[id] = int(skill_exp.get(id, 0)) + n
	EventBus.toast.emit("技能 %s +%d" % [skill_name(id), n])

func skill_level(id: String) -> int:
	return int(int(skill_exp.get(id, 0)) / 100)

func skill_name(id: String) -> String:
	for s in skills():
		if str(s.get("id", "")) == id:
			return str(s.get("name", id))
	return id

func animal_defs() -> Array:
	return data.get("animals", [])

func animal_def(id: String) -> Dictionary:
	for a in animal_defs():
		if str(a.get("id", "")) == id:
			return a
	return {}

func buy_animal(id: String) -> bool:
	var def := animal_def(id)
	if def.is_empty():
		return false
	var price := int(def.get("buy_price", 0))
	if not Inventory.spend_money(price):
		return false
	animals_owned[id] = int(animals_owned.get(id, 0)) + 1
	EventBus.toast.emit("购入 %s！（牧场 ×%d）" % [str(def.get("name", id)), animals_owned[id]])
	Achievements.check_all()
	return true

func collect_animal_products() -> int:
	var gained := 0
	for id in animals_owned:
		var n: int = animals_owned[id]
		if n <= 0:
			continue
		var def := animal_def(id)
		var prod := str(def.get("product", ""))
		if prod == "":
			continue
		# 牧歌技能加成
		var bonus := 0
		if skill_level("ranching") >= 2 and randf() < 0.3:
			bonus = 1
		var total := n + bonus
		if Inventory.add_item(prod, total):
			gained += total
			MuseumDb.mark_discover(prod)
	if gained > 0:
		Sfx.play("coin")
		EventBus.toast.emit("收获牧场产出 ×%d" % gained)
		add_exp("ranching", gained)
	return gained

func to_dict() -> Dictionary:
	return {
		"weather": weather,
		"skill_exp": skill_exp.duplicate(),
		"animals_owned": animals_owned.duplicate(),
	}

func from_dict(d: Dictionary) -> void:
	weather = str(d.get("weather", "晴朗"))
	skill_exp = d.get("skill_exp", {}).duplicate()
	animals_owned = d.get("animals_owned", {}).duplicate()
