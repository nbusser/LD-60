class_name Cursor
extends Control

enum CursorType { ARROW, BUSY, TEXT, POINTER }

const CURSORS := {
	CursorType.ARROW: Rect2(0, 0, 32, 32),
	CursorType.BUSY: Rect2(32, 0, 32, 32),
	CursorType.POINTER: Rect2(0, 32, 32, 32),
	CursorType.TEXT: Rect2(32, 32, 32, 32),
}

@export var cursor_type: CursorType = CursorType.ARROW:
	set(value):
		cursor_type = value
		_apply_cursor()

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_apply_cursor()
	_update_position()


func _process(_delta: float) -> void:
	_update_position()


func _apply_cursor() -> void:
	if not is_node_ready():
		return
	var region: Rect2 = CURSORS[cursor_type]
	sprite.region_rect = region


func _update_position() -> void:
	sprite.position = get_local_mouse_position().round()
