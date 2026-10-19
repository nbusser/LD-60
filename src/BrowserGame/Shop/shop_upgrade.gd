class_name ShopUpgrade
extends PanelContainer

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
	# Photos need smooth downscaling; small pixel-art icons scale up cleanly instead.
	if upgrade_data.icon.get_width() > 64:
		_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_icon.stretch_mode = TextureRect.STRETCH_SCALE
	%Title.text = "[b]%s[/b]" % upgrade_data.name
	if upgrade_data.description:
		%Description.text = upgrade_data.description

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
	var affordable := GameState.money >= upgrade_data.price
	_price_label.text = "Owned" if owned else "$%d" % upgrade_data.price
	_buy_button.text = "Owned" if owned else "Buy"
	_buy_button.disabled = owned or not affordable
	_price_label.add_theme_color_override(
		"font_color", Color(0.5, 0.5, 0.5) if owned or not affordable else Color.BLACK
	)
	if owned or affordable:
		_buy_button.tooltip_text = ""
	else:
		_buy_button.tooltip_text = "You need $%d more" % (upgrade_data.price - GameState.money)
