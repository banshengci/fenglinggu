extends Node
## 时间与季节

const SEASONS := ["萌芽春", "长夏", "蜜酿秋", "静雪冬"]
const DAYS_PER_SEASON := 28
const MINUTES_PER_GAME_MINUTE := 0.35  # 现实秒 / 游戏分钟（可调）

var day: int = 1
var season_index: int = 0
var hour: int = 6
var minute: int = 0
var paused: bool = false
var _accum: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if paused:
		return
	_accum += delta
	var step := MINUTES_PER_GAME_MINUTE
	while _accum >= step:
		_accum -= step
		_advance_minute()

func _advance_minute() -> void:
	minute += 10
	if minute >= 60:
		minute = 0
		hour += 1
	EventBus.time_changed.emit(hour, minute)
	if hour >= 24:
		force_sleep()

func season() -> String:
	return SEASONS[season_index]

func day_of_season() -> int:
	return ((day - 1) % DAYS_PER_SEASON) + 1

func year() -> int:
	return int((day - 1) / (DAYS_PER_SEASON * 4)) + 1

func format_clock() -> String:
	return "%02d:%02d" % [hour, minute]

func format_date() -> String:
	return "第 %d 年 · %s · 第 %d 天" % [year(), season(), day_of_season()]

func pause_time(v: bool) -> void:
	paused = v

func force_sleep() -> void:
	## 跨天：结算作物、刷新杂草/资源、推进日期
	get_tree().call_group("daily_tick", "on_new_day")
	CommissionDb.refresh_today()
	SeasonEvents.check_day()
	FestivalGames.check_today()
	RanchWeather.roll_weather(season())
	Achievements.check_all()
	day += 1
	if (day - 1) % DAYS_PER_SEASON == 0:
		season_index = (season_index + 1) % SEASONS.size()
	hour = 6
	minute = 0
	_accum = 0.0
	EventBus.day_started.emit(day, season())
	EventBus.time_changed.emit(hour, minute)
	EventBus.toast.emit("新的一天：%s" % format_date())

func to_dict() -> Dictionary:
	return {
		"day": day,
		"season_index": season_index,
		"hour": hour,
		"minute": minute,
	}

func from_dict(d: Dictionary) -> void:
	day = int(d.get("day", 1))
	season_index = int(d.get("season_index", 0))
	hour = int(d.get("hour", 6))
	minute = int(d.get("minute", 0))
	_accum = 0.0
	EventBus.time_changed.emit(hour, minute)
