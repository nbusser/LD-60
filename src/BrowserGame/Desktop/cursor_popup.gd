class_name CursorPopup
extends PanelContainer

const OFFSET_ABOVE_CURSOR := 8.0
const DURATION := 0.8

var text := ""


func _ready() -> void:
	%Label.text = text
	reset_size()
	global_position = (
		Globals.get_cursor_position() - Vector2(size.x / 2.0, size.y + OFFSET_ABOVE_CURSOR)
	)
	get_tree().create_timer(DURATION, false).timeout.connect(queue_free)
