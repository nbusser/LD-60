class_name DesktopWindow
extends Control

signal closed

@export var content_scene: PackedScene

var _dragging := false
var _drag_offset := Vector2.ZERO


func _ready() -> void:
	var content = content_scene.instantiate()
	assert(content is Control)
	%Content.add_child(content)


func _process(_delta: float) -> void:
	if not _dragging:
		return
	global_position = get_global_mouse_position() - _drag_offset


func _on_close_button_pressed() -> void:
	closed.emit()


func _on_bar_button_down() -> void:
	_dragging = true
	_drag_offset = get_global_mouse_position() - global_position


func _on_bar_button_up() -> void:
	_dragging = false
