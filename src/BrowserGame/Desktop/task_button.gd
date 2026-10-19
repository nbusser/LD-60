class_name TaskButton
extends Button

const BOLD_FONT := preload("res://assets/fonts/w95fa_13_bold.fnt")

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
	toggled.connect(_on_toggled)
	_update_content()


func _on_toggled(_pressed: bool) -> void:
	_update_font()


func _update_content() -> void:
	%WindowTitle.text = window_title
	%WindowIcon.texture = window_icon
	_update_font()


func _update_font() -> void:
	if button_pressed:
		%WindowTitle.add_theme_font_override("font", BOLD_FONT)
	else:
		%WindowTitle.remove_theme_font_override("font")
