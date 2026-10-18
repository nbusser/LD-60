extends ScrollContainer

const SHOP_UPGRADE_PRELOAD = preload("res://src/BrowserGame/Shop/shop_upgrade.tscn")

@export var upgrades: Array[UpgradeData]


func _ready():
	for upgrade in upgrades:
		_add_upgrade(upgrade)


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
