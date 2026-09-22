extends PanelContainer
## 杂货摊购买面板

@onready var title_label: Label = %ShopTitleLabel
@onready var money_label: Label = %ShopMoneyLabel
@onready var list_box: VBoxContainer = %ShopListBox
@onready var hint_label: Label = %ShopHintLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("shop_ui")
	visible = false
	EventBus.money_changed.connect(func(_m): _refresh_money())

func open_shop() -> void:
	visible = true
	get_tree().paused = true
	rebuild()

func close_shop() -> void:
	visible = false
	get_tree().paused = false

func toggle() -> void:
	if visible:
		close_shop()
	else:
		open_shop()

func _refresh_money() -> void:
	if money_label:
		money_label.text = "谷币 %d" % Inventory.money

func rebuild() -> void:
	title_label.text = "杂货摊 · %s" % TimeSystem.season()
	hint_label.text = "点击购买 · Esc / E 关闭"
	_refresh_money()
	for c in list_box.get_children():
		c.queue_free()
	var rows := ShopDb.visible_stock(TimeSystem.season())
	if rows.is_empty():
		var l := Label.new()
		l.text = "今日无货，过些天再来看看。"
		list_box.add_child(l)
		return
	for row in rows:
		var item := str(row.get("item", ""))
		var price := int(row.get("price", 0))
		var btn := Button.new()
		btn.text = "%s  —  %d 谷币" % [ItemDb.item_name(item), price]
		btn.tooltip_text = ItemDb.get_desc(item)
		btn.disabled = Inventory.money < price
		btn.pressed.connect(_buy.bind(row))
		list_box.add_child(btn)
	for a in RanchWeather.animal_defs():
		var aid := str(a.get("id", ""))
		var btn2 := Button.new()
		btn2.text = "牧场：%s  —  %d 谷币" % [str(a.get("name", aid)), int(a.get("buy_price", 0))]
		btn2.disabled = Inventory.money < int(a.get("buy_price", 0))
		btn2.pressed.connect(_buy_animal.bind(aid))
		list_box.add_child(btn2)

func _buy(row: Dictionary) -> void:
	ShopDb.buy(row)
	rebuild()

func _buy_animal(aid: String) -> void:
	RanchWeather.buy_animal(aid)
	rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close_shop()
		get_viewport().set_input_as_handled()
