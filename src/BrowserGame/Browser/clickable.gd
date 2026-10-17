# Any clickable link
# Abstract class

class_name Clickable

extends RichTextLabel


func _on_meta_hover_started(_meta: Variant) -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_meta_hover_ended(_meta: Variant) -> void:
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_meta_clicked(_meta: Variant) -> void:
	text = text.replace("=blue", "=purple")
