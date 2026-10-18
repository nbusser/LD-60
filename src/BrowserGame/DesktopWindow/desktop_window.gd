class_name DesktopWindow
extends Control

signal closed
signal dragged
signal content_loaded

@export var content_scene: PackedScene
# Arbitrary callback to be called with the content_scene
@export var on_instantiate_callback: Callable

var _dragging := false
var _drag_offset := Vector2.ZERO

var _loading := false


func _ready() -> void:
	_loading = true
	var content = content_scene.instantiate()
	assert(content is Control)

	if on_instantiate_callback != null:
		on_instantiate_callback.call(content)

	await get_tree().create_timer(randf_range(0.8, 1.5)).timeout
	%Loading.visible = false
	_loading = false

	%Content.add_child(content)
	# Shrink to fit the content (a Control is never smaller than its minimum size)
	reset_size()
	minimum_size_changed.connect(reset_size)
	content_loaded.emit()


func _process(_delta: float) -> void:
	if not _dragging:
		return
	global_position = Globals.get_cursor_position() - _drag_offset


func _on_close_button_pressed() -> void:
	closed.emit()


func _on_bar_button_down() -> void:
	_dragging = true
	_drag_offset = Globals.get_cursor_position() - global_position
	dragged.emit(self)


func _on_bar_button_up() -> void:
	_dragging = false


func is_loading() -> bool:
	return _loading
