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
	Globals.register_cursor(self)
	_apply_cursor()
	_update_position()


func _exit_tree() -> void:
	Globals.unregister_cursor(self)


func _process(_delta: float) -> void:
	_update_position()


func _apply_cursor() -> void:
	if not is_node_ready():
		return
	var region: Rect2 = CURSORS[cursor_type]
	sprite.region_rect = region


func _update_position() -> void:
	sprite.position = _clamp_center_to_screen(get_local_mouse_position()).round()


func get_global_cursor_position() -> Vector2:
	return get_global_transform() * sprite.position


func _clamp_center_to_screen(pos: Vector2) -> Vector2:
	if size.x <= 0.0 or size.y <= 0.0:
		return pos
	return pos.clamp(Vector2(0, 0), size)
