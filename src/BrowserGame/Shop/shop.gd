extends ScrollContainer

const SHOP_UPGRADE_PRELOAD = preload("res://src/BrowserGame/Shop/shop_upgrade.tscn")

@export var upgrades: Array[UpgradeData]


func _ready():
	for u in upgrades:
		%Grid.add_child(_create_upgrade_instance(u))


func _create_upgrade_instance(u: UpgradeData):
	var instance = SHOP_UPGRADE_PRELOAD.instantiate()
	instance.upgrade_data = u
	instance.upgrade_clicked.connect(_upgrade_clicked)
	return instance


func _upgrade_clicked(u: ShopUpgrade) -> void:
	u.queue_free()
	for unlock in u.upgrade_data.unlocks:
		u.add_sibling(_create_upgrade_instance(unlock))
