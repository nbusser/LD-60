extends ScrollContainer

# TODO remember bought

const SHOP_UPGRADE_PRELOAD = preload("res://src/BrowserGame/Shop/shop_upgrade.tscn")

@export var upgrades : Array[UpgradeData]

func _ready():
	for u in upgrades:
		var instance = SHOP_UPGRADE_PRELOAD.instantiate()
		instance.upgrade_data = u
		#instance.category_clicked.connect(_category_clicked)
		%Grid.add_child(instance)
