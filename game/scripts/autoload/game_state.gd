extends Node
## 运行时游戏状态

var player_name: String = "旅人"
var met_npcs: Dictionary = {}
var friendship: Dictionary = {}
var flags: Dictionary = {}
var farm_state: Array = []
var wind_shards: int = 0
var quest_state: Dictionary = {}
var bell_bonus: bool = false
var resonant_plots: Dictionary = {}
var dialogue_log: Array = []

func append_dialogue_log(speaker: String, line: String) -> void:
	dialogue_log.append({"speaker": speaker, "line": line, "day": TimeSystem.day if "day" in TimeSystem else 0})
	if dialogue_log.size() > 300:
		dialogue_log = dialogue_log.slice(dialogue_log.size() - 300)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func has_met(id: String) -> bool:
	return bool(met_npcs.get(id, false))

func meet(id: String) -> void:
	if not has_met(id):
		met_npcs[id] = true
		friendship[id] = 0

func add_friendship(id: String, n: int) -> void:
	meet(id)
	friendship[id] = int(friendship.get(id, 0)) + n

func friendship_of(id: String) -> int:
	return int(friendship.get(id, 0))

func add_flag(key: String, value = true) -> void:
	flags[key] = value

func get_flag(key: String, default = false):
	return flags.get(key, default)

func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"met_npcs": met_npcs.duplicate(),
		"friendship": friendship.duplicate(),
		"flags": flags.duplicate(),
		"farm_state": farm_state.duplicate(true),
		"wind_shards": wind_shards,
		"dialogue_log": dialogue_log.duplicate(true),
		"quest_state": QuestLog.to_dict(),
		"heart_seen": HeartDb.to_dict(),
		"story": StoryDb.to_dict(),
		"commissions": CommissionDb.to_dict(),
		"museum": MuseumDb.to_dict(),
		"achievements": Achievements.to_dict(),
		"season_events": SeasonEvents.to_dict(),
		"festival_games": FestivalGames.to_dict(),
		"ranch": RanchWeather.to_dict(),
	}

func from_dict(d: Dictionary) -> void:
	player_name = str(d.get("player_name", "旅人"))
	met_npcs = d.get("met_npcs", {}).duplicate()
	friendship = d.get("friendship", {}).duplicate()
	flags = d.get("flags", {}).duplicate()
	farm_state = d.get("farm_state", []).duplicate(true)
	wind_shards = int(d.get("wind_shards", 0))
	dialogue_log = d.get("dialogue_log", []).duplicate(true)
	quest_state = d.get("quest_state", {}).duplicate()
	QuestLog.from_dict(quest_state)
	HeartDb.from_dict(d.get("heart_seen", {}))
	StoryDb.from_dict(d.get("story", {}))
	CommissionDb.from_dict(d.get("commissions", {}))
	MuseumDb.from_dict(d.get("museum", {}))
	Achievements.from_dict(d.get("achievements", {}))
	SeasonEvents.from_dict(d.get("season_events", {}))
	FestivalGames.from_dict(d.get("festival_games", {}))
	RanchWeather.from_dict(d.get("ranch", {}))

func start_new_game_plus() -> void:
	var museum := MuseumDb.to_dict()
	var ach := Achievements.to_dict()
	var ng := int(flags.get("ng_plus", 0)) + 1
	from_dict({"ng_plus": ng})
	MuseumDb.from_dict(museum)
	Achievements.from_dict(ach)
	flags["ng_plus"] = ng
	StoryDb.bells_repaired = 0
	StoryDb.festival_done = false
	EventBus.toast.emit("新周目+%d 开始！图鉴与成就已继承。" % ng)
