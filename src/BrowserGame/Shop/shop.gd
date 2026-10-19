extends ScrollContainer

const SHOP_UPGRADE_PRELOAD = preload("res://src/BrowserGame/Shop/shop_upgrade.tscn")

@export var upgrades: Array[UpgradeData]

@onready var _balance_label: Label = %BalanceLabel


func _ready():
	GameState.money_changed.connect(_on_money_changed)
	_on_money_changed(GameState.money)
	for upgrade in upgrades:
		_add_upgrade(upgrade)
	_update_empty_state()


func _on_money_changed(value: int) -> void:
	_balance_label.text = "You have $%d" % value


func _add_upgrade(upgrade: UpgradeData) -> void:
	if GameState.is_upgrade_owned(upgrade.id):
		for unlock in upgrade.unlocks:
			_add_upgrade(unlock)
		return
	%Grid.add_child(_create_upgrade_instance(upgrade))


func _create_upgrade_instance(upgrade: UpgradeData) -> ShopUpgrade:
	var instance: ShopUpgrade = SHOP_UPGRADE_PRELOAD.instantiate()
	instance.upgrade_data = upgrade
	instance.upgrade_clicked.connect(_upgrade_clicked)
	return instance


func _upgrade_clicked(shop_upgrade: ShopUpgrade) -> void:
	shop_upgrade.queue_free()
	for unlock in shop_upgrade.upgrade_data.unlocks:
		_add_upgrade(unlock)
	_update_empty_state.call_deferred()


func _update_empty_state() -> void:
	%EmptyState.visible = %Grid.get_child_count() == 0
