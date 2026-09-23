extends Node
## 主场景：标题 → 游戏 → 暂停

@onready var hud: Control = $UI/HUD
@onready var inventory_ui: Control = $UI/InventoryPanel
@onready var craft_ui: Control = $UI/CraftPanel
@onready var shop_ui: Control = $UI/ShopPanel
@onready var pause_menu: Control = $UI/PauseMenu
@onready var title_screen: Control = $UI/TitleScreen
@onready var map_ui: Control = $UI/MapPanel
@onready var world_map_ui: Control = $UI/WorldMapPanel
@onready var photo_ui: Control = $UI/PhotoMode
@onready var museum_ui: Control = $UI/MuseumPanel
@onready var look_ui: Control = $UI/LookPanel
@onready var settings_ui: Control = $UI/SettingsPanel
@onready var harp_ui: Control = $UI/WindHarp
@onready var area_manager: Node = $AreaManager

var _game_started := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	title_screen.visible = true
	hud.visible = false
	title_screen.start_pressed.connect(_on_start)
	pause_menu.resume_requested.connect(func(): pause_menu.close())
	pause_menu.save_requested.connect(func(): SaveSystem.save_game())
	pause_menu.load_requested.connect(func(): SaveSystem.load_game(); pause_menu.close())
	pause_menu.quit_requested.connect(_back_to_title)
	if world_map_ui.has_signal("traveled"):
		world_map_ui.traveled.connect(_on_world_travel)

func _on_world_travel(region_id: String) -> void:
	area_manager.travel_to(region_id)

func _try_confess_key() -> void:
	for id in GameState.friendship:
		if BondDb.can_confess(str(id)):
			BondDb.try_confess(str(id))
			return
	EventBus.toast.emit("还没有可以告白的对象（羁绊 80+）")

func _try_wedding_key() -> void:
	if BondDb.try_wedding():
		return
	EventBus.toast.emit("还不能举办婚礼（需伴侣羁绊 120+）")
	world_map_ui.close()

func _on_start(load_save: bool) -> void:
	title_screen.visible = false
	hud.visible = true
	get_tree().paused = false
	_game_started = true
	if load_save:
		SaveSystem.load_game()
		EventBus.toast.emit("欢迎回来。")
	else:
		Inventory.reset_starting_kit()
		GameState.from_dict({})
		QuestLog.from_dict({})
		TimeSystem.day = 1
		TimeSystem.season_index = 0
		TimeSystem.hour = 6
		TimeSystem.minute = 0
		area_manager.travel_to("town", 0, true)
		EventBus.toast.emit("欢迎来到风铃谷。跟着左上角目标行动吧！")
	Bgm.refresh_from_time()

func _back_to_title() -> void:
	pause_menu.close()
	get_tree().paused = true
	title_screen.visible = true
	hud.visible = false
	_game_started = false
	title_screen.load_btn.disabled = not SaveSystem.has_save()

func _unhandled_input(event: InputEvent) -> void:
	if not _game_started:
		return
	if pause_menu.visible:
		if event.is_action_pressed("ui_pause") or event.is_action_pressed("ui_cancel"):
			pause_menu.close()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_pause"):
		_close_panels()
		pause_menu.open()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("open_inventory"):
		_close_panels_except(inventory_ui)
		inventory_ui.toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_craft"):
		if craft_ui.visible:
			craft_ui.toggle()
		else:
			_close_panels_except(craft_ui)
			craft_ui.open_station("workbench")
	elif event.is_action_pressed("bond_confess"):
		_try_confess_key()
	elif event.is_action_pressed("bond_wedding"):
		_try_wedding_key()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if inventory_ui.visible:
			inventory_ui.toggle()
		if craft_ui.visible:
			craft_ui.toggle()
		if shop_ui.visible:
			shop_ui.close_shop()
		get_viewport().set_input_as_handled()
	elif event.is_physical_key_pressed(KEY_L):
		SaveSystem.load_game()
		get_viewport().set_input_as_handled()
	elif event.is_physical_key_pressed(KEY_T):
		if not get_tree().paused:
			if area_manager and area_manager.current_area == "mine":
				EventBus.toast.emit("在矿洞睡不着……回镇上床铺吧。")
			else:
				SaveSystem.save_game()
				TimeSystem.force_sleep()
				if area_manager:
					area_manager.heal_full()
		get_viewport().set_input_as_handled()
	elif event.is_physical_key_pressed(KEY_R):
		if area_manager:
			area_manager.heal_full()
			EventBus.toast.emit("原地休整，HP 回满。")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_map"):
		world_map_ui.toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_harp"):
		harp_ui.toggle()
		get_viewport().set_input_as_handled()
	elif event.is_physical_key_pressed(KEY_U):
		museum_ui.toggle()
		get_viewport().set_input_as_handled()
	elif event.is_physical_key_pressed(KEY_O):
		look_ui.toggle()
		get_viewport().set_input_as_handled()
	elif event.is_physical_key_pressed(KEY_F1):
		settings_ui.toggle()
		get_viewport().set_input_as_handled()
	elif event.is_physical_key_pressed(KEY_F2):
		GameState.start_new_game_plus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("slot_1"):
		_select_slot(0)
	elif event.is_action_pressed("slot_2"):
		_select_slot(1)
	elif event.is_action_pressed("slot_3"):
		_select_slot(2)
	elif event.is_action_pressed("slot_4"):
		_select_slot(3)
	elif event.is_action_pressed("slot_next"):
		_cycle_slot(1)
	elif event.is_action_pressed("slot_prev"):
		_cycle_slot(-1)

func _select_slot(index: int) -> void:
	if not inventory_ui.has_method("selected_item_id"):
		return
	inventory_ui.selected_index = index
	inventory_ui.rebuild()
	Sfx.play("click", 1.3, -12.0)

func _close_panels() -> void:
	if inventory_ui.visible:
		inventory_ui.toggle()
	if craft_ui.visible:
		craft_ui.toggle()
	if shop_ui.visible:
		shop_ui.close_shop()

func _close_panels_except(keep: Control) -> void:
	if inventory_ui.visible and inventory_ui != keep:
		inventory_ui.toggle()
	if craft_ui.visible and craft_ui != keep:
		craft_ui.toggle()
	if shop_ui.visible and shop_ui != keep:
		shop_ui.close_shop()

func _cycle_slot(dir: int) -> void:
	if not inventory_ui.has_method("selected_item_id"):
		return
	var idx: int = inventory_ui.selected_index
	idx = wrapi(idx + dir, 0, Inventory.MAX_SLOTS)
	inventory_ui.selected_index = idx
	inventory_ui.rebuild()
	Sfx.play("click", 1.2, -12.0)
