class_name UpgradeData
extends Resource

@export var id: String
@export var name: String
@export var description: String
@export var price := 10
@export var icon: Texture2D
@export var unlocks: Array[UpgradeData]
# Shown in an error popup once bought, for upgrades that never work
@export_multiline var purchase_error: String
