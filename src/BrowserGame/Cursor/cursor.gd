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
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _process(_delta: float) -> void:
	_update_position()
	_update_real_cursor()


func _update_real_cursor() -> void:
	var pointer_inside := _is_pointer_inside_desktop()
	var desired_mode := Input.MOUSE_MODE_HIDDEN if pointer_inside else Input.MOUSE_MODE_VISIBLE
	if Input.get_mouse_mode() != desired_mode:
		Input.set_mouse_mode(desired_mode)
	sprite.visible = pointer_inside


func _is_pointer_inside_desktop() -> bool:
	if not _is_pointer_inside_window():
		return false

	var container := get_viewport().get_parent() as SubViewportContainer
	if container == null:
		return true
	var visible_rect := container.get_global_transform() * Rect2(Vector2.ZERO, container.size)
	return visible_rect.has_point(get_tree().root.get_mouse_position())


func _is_pointer_inside_window() -> bool:
	var window := get_window()
	if window == null or not window.has_focus():
		return false
	if window.is_embedded():
		return true
	return Rect2i(window.position, window.size).has_point(DisplayServer.mouse_get_position())


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
