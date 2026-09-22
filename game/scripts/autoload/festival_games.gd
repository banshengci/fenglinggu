extends Node
## 大型活动赛事

const PATH := "res://data/ranch_weather_skills.json"

var data: Dictionary = {}
var played: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		data = parsed

func activities() -> Array:
	return data.get("activities", [])

func check_today() -> void:
	var season := TimeSystem.season()
	var day := TimeSystem.day_of_season()
	for a in activities():
		if str(a.get("season", "")) != season:
			continue
		if int(a.get("day", 0)) != day:
			continue
		var id := str(a.get("id", ""))
		if played.get(id, false):
			continue
		_run(a)

func _run(a: Dictionary) -> void:
	var id := str(a.get("id", ""))
	played[id] = TimeSystem.day
	var title := str(a.get("name", "活动"))
	var lines: Array = ["【%s】全镇的人都来了。" % title]
	var reward_money := 80
	var reward_item := "wind_shard"
	match id:
		"fishing_contest":
			lines.append("江澄：今天比谁的鱼更精神！")
			if Inventory.count_of("carp_spring") + Inventory.count_of("bluegill") >= 1:
				lines.append("你带的鱼被大伙夸了一圈。")
				reward_money = 200
			else:
				lines.append("下次记得带鱼来。")
				reward_money = 50
		"cook_off":
			lines.append("厨娘：锅铲就是指挥棒！")
			if Inventory.count_of("turnip_cake") + Inventory.count_of("berry_jam") >= 1:
				lines.append("你的料理被端上了主桌。")
				reward_item = "berry_jam"
			else:
				reward_money = 40
		"pet_show":
			lines.append("萌宠们在草地上打滚。")
			if RanchWeather.animals_owned.size() > 0:
				lines.append("你的牧场队拿了最佳笑容奖。")
				reward_money = 150
		"stargazing":
			lines.append("风脊崖顶挤满了仰望的人。")
			reward_item = "wind_shard"
			reward_money = 60
	lines.append("（奖励已发放）")
	EventBus.dialogue_started.emit(lines, "system")
	Inventory.add_money(reward_money)
	if reward_item != "":
		Inventory.add_item(reward_item, 1)
	Sfx.play("bell", 1.0, -5.0)

func to_dict() -> Dictionary:
	return played.duplicate()

func from_dict(d: Dictionary) -> void:
	played = d.duplicate()
