class_name Icon
extends TextureButton

signal double_clicked
signal selected

@export var text: String

var is_selected := false:
	set(value):
		if value:
			modulate = Color.BLUE
			selected.emit(self)
		else:
			modulate = Color.WHITE


func _ready():
	%Label.text = text
	button_mask = MOUSE_BUTTON_MASK_LEFT


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.double_click:
			double_clicked.emit()
		else:
			is_selected = true
