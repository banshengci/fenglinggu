extends Node
## 节令联赛：5 场赛事积分 + 奖杯架 + 本地榜

const TROPHY_IDS := ["sprout_cup", "longsun_cup", "harvest_cup", "snowbell_cup", "grand_prix"]

const EVENTS := [
	{"id": "sprout_cup", "name": "萌芽杯 · 播种竞速", "season": "萌芽春", "skill": "farming"},
	{"id": "longsun_cup", "name": "长夏杯 · 垂钓王", "season": "长夏", "skill": "fishing"},
	{"id": "harvest_cup", "name": "丰年杯 · 料理王", "season": "丰获秋", "skill": "cooking"},
	{"id": "snowbell_cup", "name": "静雪杯 · 矿脉冲刺", "season": "静雪冬", "skill": "mining"},
	{"id": "grand_prix", "name": "风铃谷大奖赛", "season": "", "skill": "all"},
]

var season_scores: Dictionary = {}  # event_id -> best score
var trophies: Dictionary = {}       # trophy_id -> true
var board: Array = []               # [{name, score, year, season}]

func to_dict() -> Dictionary:
	return {
		"season_scores": season_scores.duplicate(),
		"trophies": trophies.duplicate(),
		"board": board.duplicate(true),
	}

func from_dict(d: Dictionary) -> void:
	season_scores = d.get("season_scores", {}).duplicate()
	trophies = d.get("trophies", {}).duplicate()
	board = d.get("board", []).duplicate(true)

func score_event(event_id: String, score: int, player_name: String = "你") -> void:
	var prev := int(season_scores.get(event_id, 0))
	if score > prev:
		season_scores[event_id] = score
		EventBus.toast.emit("联赛新纪录：%d 分！" % score)
	_submit_board(player_name, score)
	# 夺杯：分数阈值
	var need := 60
	if score >= need and not trophies.get(event_id, false):
		trophies[event_id] = true
		Inventory.add_item("wind_shard", 2)
		Inventory.add_money(200)
		EventBus.dialogue_started.emit([
			"【%s】颁奖台升起。" % _event_name(event_id),
			"你举起了奖杯，风铃谷掌声如潮。",
		], "system")
		EventBus.toast.emit("获得奖杯：%s" % _event_name(event_id))
	EventBus.hud_refresh.emit()

func _event_name(id: String) -> String:
	for e in EVENTS:
		if str(e.get("id", "")) == id:
			return str(e.get("name", id))
	return id

func _submit_board(name: String, score: int) -> void:
	board.append({
		"name": name,
		"score": score,
		"year": TimeSystem.year(),
		"season": TimeSystem.season(),
	})
	board.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))
	if board.size() > 10:
		board.resize(10)

func board_text() -> String:
	if board.is_empty():
		return "本地榜：暂无记录"
	var parts: PackedStringArray = []
	var i := 1
	for row in board:
		parts.append("%d.%s %d" % [i, str(row.get("name", "?")), int(row.get("score", 0))])
		i += 1
		if i > 5:
			break
	return "本地榜｜" + "　".join(parts)

func trophy_shelf_text() -> String:
	var got := 0
	var parts: PackedStringArray = []
	for tid in TROPHY_IDS:
		if trophies.get(tid, false):
			got += 1
			parts.append("★")
		else:
			parts.append("☆")
	return "奖杯架 %d/%d %s" % [got, TROPHY_IDS.size(), " ".join(parts)]

func run_today_league() -> void:
	# 当日若与某赛事同季同日，按技能分自动结算
	var season := TimeSystem.season()
	var skill_sum := 0
	for s in ["farming", "fishing", "cooking", "mining"]:
		skill_sum += RanchWeather.skill_level(s)
	for e in EVENTS:
		if str(e.get("season", "")) != season:
			continue
		if int(TimeSystem.day_of_season()) != 15:
			continue
		var sk := str(e.get("skill", "all"))
		var base := skill_sum * 4 if sk == "all" else RanchWeather.skill_level(sk) * 10
		base += randi_range(10, 30)
		score_event(str(e.get("id", "")), base)
		return
	# 大奖赛：季末
	if TimeSystem.day_of_season() >= 26:
		var sk2 := str(EVENTS[4].get("skill", "all"))
		var base2 := skill_sum * 3 + randi_range(5, 25)
		score_event(str(EVENTS[4].get("id", "")), base2)
