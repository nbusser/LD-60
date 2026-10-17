# Any clickable link
# Abstract class

class_name ClickableLabel

extends RichTextLabel


func set_label_text(title: String, description: String):
	text = "[color=blue][url]" + title + "[/url][/color][br][color=black]" + description


func _on_meta_hover_started(_meta: Variant) -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_meta_hover_ended(_meta: Variant) -> void:
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_meta_clicked(_meta: Variant) -> void:
	# TODO not remembered
	text = text.replace("=blue", "=purple")
