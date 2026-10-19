class_name ShopUpgrade
extends VBoxContainer

signal upgrade_clicked(shop_upgrade: ShopUpgrade)

var upgrade_data: UpgradeData:
	set(value):
		assert(upgrade_data == null)
		upgrade_data = value

@onready var _icon: TextureRect = %Icon
@onready var _price_label: Label = %PriceLabel
@onready var _buy_button: Button = %BuyButton


func _ready() -> void:
	assert(upgrade_data != null && upgrade_data.icon != null && upgrade_data.name != null)
	_icon.texture = upgrade_data.icon
	%Title.text = "[color=blue][url]" + upgrade_data.name
	if upgrade_data.description:
		%Description.text = "[color=black]" + upgrade_data.description

	_buy_button.pressed.connect(_on_buy_pressed)
	GameState.money_changed.connect(_on_money_changed)
	GameState.upgrades_changed.connect(_refresh)
	_refresh()


func _on_money_changed(_value: int) -> void:
	_refresh()


func _on_buy_pressed() -> void:
	if GameState.try_buy_upgrade(upgrade_data):
		Sfx.click()
		upgrade_clicked.emit(self)


func _refresh() -> void:
	var owned := GameState.is_upgrade_owned(upgrade_data.id)
	_price_label.text = "Owned" if owned else "$%d" % upgrade_data.price
	_buy_button.text = "Owned" if owned else "Buy"
	_buy_button.disabled = owned or GameState.money < upgrade_data.price
