extends Node
## 极简本地化表

var locale := "zh_CN"

const TABLE := {
	"title": {"zh_CN": "风铃谷", "en_US": "Wind Chime Valley"},
	"new_game": {"zh_CN": "新游戏", "en_US": "New Game"},
	"continue": {"zh_CN": "读取存档", "en_US": "Continue"},
	"quit": {"zh_CN": "退出", "en_US": "Quit"},
	"inventory": {"zh_CN": "背包", "en_US": "Inventory"},
	"craft": {"zh_CN": "合成", "en_US": "Craft"},
	"map": {"zh_CN": "世界地图", "en_US": "World Map"},
	"museum": {"zh_CN": "图鉴成就", "en_US": "Museum"},
	"money": {"zh_CN": "谷币", "en_US": "Coins"},
	"settings": {"zh_CN": "设置", "en_US": "Settings"},
}

func get_text(key: String) -> String:
	if TABLE.has(key):
		return str(TABLE[key].get(locale, key))
	return key

func set_locale(l: String) -> void:
	locale = l
	EventBus.hud_refresh.emit()
	EventBus.toast.emit("语言 / Language: %s" % locale)

func toggle_locale() -> void:
	set_locale("en_US" if locale == "zh_CN" else "zh_CN")
