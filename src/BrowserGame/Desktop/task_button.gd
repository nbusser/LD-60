class_name TaskButton
extends Button

var window_title: String = "":
	set(value):
		window_title = value
		if is_node_ready():
			_update_content()

var window_icon: Texture2D:
	set(value):
		window_icon = value
		if is_node_ready():
			_update_content()


func _ready() -> void:
	_update_content()


func _update_content() -> void:
	%WindowTitle.text = window_title
	%WindowIcon.texture = window_icon
