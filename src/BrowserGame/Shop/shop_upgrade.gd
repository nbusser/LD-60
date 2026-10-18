class_name ShopUpgrade
extends VBoxContainer

signal upgrade_clicked(UpgradeData)

var upgrade_data: UpgradeData:
	set(value):
		assert(upgrade_data == null)
		upgrade_data = value


func _ready() -> void:
	assert(upgrade_data != null && upgrade_data.icon != null && upgrade_data.name != null)
	%Icon.set_texture(upgrade_data.icon)
	%Title.text = "[color=blue][url]" + upgrade_data.name
	if upgrade_data.description:
		%Description.text = "[color=black]" + upgrade_data.description
	self.gui_input.connect(
		func(event):
			if (
				event is InputEventMouseButton
				and event.pressed
				and event.button_index == MOUSE_BUTTON_LEFT
			):
				upgrade_clicked.emit(self)
	)
