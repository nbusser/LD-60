extends VBoxContainer

var upgrade_data: UpgradeData:
	set(value):
		assert(upgrade_data == null)
		upgrade_data = value


func _ready() -> void:
	assert(upgrade_data != null)
	if upgrade_data.icon:
		%Icon.set_texture(upgrade_data.icon)
	if upgrade_data.name:
		%Title.text = "[color=blue][url]" + upgrade_data.name
	if upgrade_data.description:
		%Description.text = "[color=black]" + upgrade_data.description
