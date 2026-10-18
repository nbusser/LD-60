extends ScrollContainer

# TODO remember bought

const SHOP_UPGRADE_PRELOAD = preload("res://src/BrowserGame/Shop/shop_upgrade.tscn")

@export var upgrades: Array[UpgradeData]


func _ready():
	for u in upgrades:
		var instance = SHOP_UPGRADE_PRELOAD.instantiate()
		instance.upgrade_data = u
		instance.upgrade_clicked.connect(_upgrade_clicked)
		%Grid.add_child(instance)


func _upgrade_clicked(u: ShopUpgrade) -> void:
	print(u.upgrade_data.name + " clicked")
