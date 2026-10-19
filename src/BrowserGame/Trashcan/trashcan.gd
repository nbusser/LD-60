extends ScrollContainer

@onready var restore_button := %RestoreButton
@onready var grid := %Grid


func _on_restore_button_toggled(_toggled_on: bool) -> void:
	restore_button.disabled = true
	grid.visible = false
	print("grid ", grid.visible)
	Globals.credits_restored.emit()
