class_name DesktopWindow
extends Control

signal closed
signal dragged
signal content_loaded

const UNFOCUSED_TITLE_BAR_ALPHA := 0.6

@export var window_icon: Texture2D:
	set(value):
		window_icon = value
		if is_node_ready():
			_update_title_bar()

@export var window_title: String = "Window Title":
	set(value):
		window_title = value
		if is_node_ready():
			_update_title_bar()

@export var content_scene: PackedScene
# Arbitrary callback to be called with the content_scene
@export var on_instantiate_callback: Callable

var _dragging := false
var _drag_offset := Vector2.ZERO

var _loading := false
var _busy := false

@onready var _title_bar: Button = $VBoxContainer/Bar/Bar
@onready var _close_button: TextureButton = $VBoxContainer/Bar/CloseButton


func _ready() -> void:
	_update_title_bar()
	_loading = true
	Sfx.play_harddrive_short()
	var content = content_scene.instantiate()
	assert(content is Control)

	if on_instantiate_callback != null:
		on_instantiate_callback.call(content)

	await get_tree().create_timer(randf_range(0.8, 1.5), false).timeout
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


func _clamp_to_desktop() -> void:
	var desktop := _get_desktop()
	if desktop == null:
		return

	# Keep the title bar between the top of the desktop and the task bar.
	var window_area := desktop.get_window_area()
	var title_bar_height := ($VBoxContainer/Bar as Control).size.y
	global_position.y = clampf(
		global_position.y, window_area.position.y, window_area.end.y - title_bar_height
	)


func _get_desktop() -> Desktop:
	var node := get_parent()
	while node != null:
		if node is Desktop:
			return node
		node = node.get_parent()
	return null


func _on_close_button_pressed() -> void:
	# a busy window (e.g. the setup installing) can't be closed
	if _busy:
		return
	closed.emit()


func _on_bar_button_down() -> void:
	_dragging = true
	_drag_offset = Globals.get_cursor_position() - global_position
	dragged.emit(self)


func _on_bar_button_up() -> void:
	_dragging = false
	_clamp_to_desktop()


func set_busy(value: bool) -> void:
	_busy = value
	_close_button.disabled = value
	_close_button.modulate.a = 0.5 if value else 1.0


func is_busy() -> bool:
	return _loading or _busy


func set_focused(value: bool) -> void:
	_title_bar.self_modulate.a = 1.0 if value else UNFOCUSED_TITLE_BAR_ALPHA


func _update_title_bar() -> void:
	%WindowIcon.texture = window_icon
	%WindowTitle.text = window_title
