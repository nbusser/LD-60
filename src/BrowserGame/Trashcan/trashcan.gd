extends ScrollContainer

@onready var restore_button := %RestoreButton


func _on_restore_button_toggled(_toggled_on: bool) -> void:
	restore_button.disabled
