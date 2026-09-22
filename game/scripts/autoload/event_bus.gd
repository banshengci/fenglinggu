extends Node
## 全局信号总线

signal toast(message: String)
signal day_started(day: int, season: String)
signal time_changed(hour: int, minute: int)
signal money_changed(amount: int)
signal inventory_changed
signal dialogue_started(lines: Array, npc_id: String)
signal dialogue_ended
signal crop_state_changed
signal hud_refresh
