# Any clickable link
# Abstract class

class_name ClickableLabel

extends RichTextLabel

const LINK_COLOR := "#0000ee"
const VISITED_COLOR := "#551a8b"
const UNDERLINE_OFFSET := 2.0


func _ready() -> void:
	_shift_underline()


func set_label_text(value: String) -> void:
	text = "[color=%s][url]%s[/url][/color]" % [LINK_COLOR, value]


func _shift_underline() -> void:
	# RichTextLabel has no underline-offset setting, so adjust the font cache metric.
	var font_file := _find_font_file(get_theme_font("normal_font"))
	if font_file == null:
		return

	var font_size := get_theme_font_size("normal_font_size")
	font_file.get_height(font_size)
	font_file.set_cache_underline_position(0, font_size, UNDERLINE_OFFSET)


func _find_font_file(font: Font) -> FontFile:
	var current_font: Font = font
	while current_font is FontVariation:
		current_font = (current_font as FontVariation).base_font
	return current_font as FontFile


func _on_meta_hover_started(_meta: Variant) -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_meta_hover_ended(_meta: Variant) -> void:
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_meta_clicked(_meta: Variant) -> void:
	text = text.replace(LINK_COLOR, VISITED_COLOR)
