class_name Icon
extends TextureButton

signal double_clicked

@export var text: String

var selected := false


func _ready():
	$Label.text = text
	button_mask = MOUSE_BUTTON_MASK_LEFT


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.double_click:
			double_clicked.emit()
		else:
			selected = true
			modulate = Color.BLUE
