# Any clickable link
# Abstract class

class_name ClickableLabel

extends RichTextLabel

var _clipboard_text := ""


func set_label_text(title: String, description: String, clipboard_text: String = ""):
	_clipboard_text = clipboard_text
	var meta := clipboard_text if not clipboard_text.is_empty() else title
	text = "[color=blue][url=%s]" % meta + title + "[/url][/color][br][color=black]" + description


func _on_meta_hover_started(_meta: Variant) -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_meta_hover_ended(_meta: Variant) -> void:
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_meta_clicked(_meta: Variant) -> void:
	if not _clipboard_text.is_empty() and GameState.is_upgrade_owned("copy_paste"):
		Globals.clipboard = _clipboard_text
	text = text.replace("=blue", "=purple")
