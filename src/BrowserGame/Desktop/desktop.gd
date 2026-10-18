class_name Desktop
extends Control

@export var programs: Array[Program]

var _programs_to_window: Dictionary[Program, DesktopWindow] = {}

@onready var icon_scene = preload("res://src/BrowserGame/Icon/icon.tscn")
@onready
var desktop_window_scene = preload("res://src/BrowserGame/DesktopWindow/desktop_window.tscn")
@onready var error_popup_scene = preload("res://src/BrowserGame/DesktopWindow/error_popup.tscn")
@onready var cursor = $Cursor
@onready var pinny: Pinny = %Pinny


func _window_to_foreground(selected_window: DesktopWindow):
	%Windows.move_child(selected_window, -1)


func _create_window(
	program: Program,
	app_scene: PackedScene = program.app_scene,
	callback: Callable = func(_node: Control): pass
) -> DesktopWindow:
	var desktop_window: DesktopWindow = desktop_window_scene.instantiate()
	desktop_window.window_title = program.icon_label
	desktop_window.window_icon = program.icon_texture
	desktop_window.content_scene = app_scene
	desktop_window.on_instantiate_callback = callback
	desktop_window.closed.connect(
		func():
			_close_window(program)
			Sfx.click()
	)
	desktop_window.dragged.connect(_window_to_foreground)
	_programs_to_window.set(program, desktop_window)
	return desktop_window


func _create_error_popup(program: Program, error_message: String) -> DesktopWindow:
	var desktop_window = _create_window(
		program,
		error_popup_scene,
		func(error_popup: ErrorPopup): error_popup.error_message = error_message
	)
	return desktop_window


func _center_window(desktop_window: DesktopWindow) -> void:
	desktop_window.position = ((size - desktop_window.size) / 2).floor()


func _open_or_show_window(program: Program):
	var desktop_window: DesktopWindow = _programs_to_window.get(program)
	if desktop_window == null or not is_instance_valid(desktop_window):
		# Create the window
		if program.app_scene != null:
			desktop_window = _create_window(program)
		else:
			desktop_window = _create_error_popup(program, "Program not found")

		_programs_to_window.set(program, desktop_window)
		%Windows.add_child(desktop_window)
		_center_window(desktop_window)

		# center window again once loaded
		desktop_window.content_loaded.connect(_center_window.bind(desktop_window), CONNECT_ONE_SHOT)
	else:
		_window_to_foreground(desktop_window)
		# Reset window position
		_center_window(desktop_window)


func _close_window(program: Program):
	var desktop_window: DesktopWindow = _programs_to_window.get(program)
	if desktop_window != null and is_instance_valid(desktop_window):
		desktop_window.queue_free()
	_programs_to_window.set(program, null)


func _ready() -> void:
	for program in programs:
		_programs_to_window.set(program, null)

		var icon: Icon = icon_scene.instantiate()
		icon.text = program.icon_label
		icon.texture_normal = program.icon_texture
		icon.double_clicked.connect(
			func():
				_open_or_show_window(program)
				Sfx.click()
		)
		# On icon selected, un-select all other icons
		icon.selected.connect(
			func(selected: Icon):
				for other in %Icons.get_children():
					assert(other is Icon)
					if other == selected:
						continue
					other.is_selected = false
		)
		%Icons.add_child(icon)

	pinny.visit(
		["Le sang de tes morts, tu m'entends?", "Inch'allah sur le coran de namek"],
		Pinny.Mood.ANGRY
	)


func _on_background_color_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for icon in %Icons.get_children():
			icon.is_selected = false


func _get_windows() -> Array[DesktopWindow]:
	var windows: Array[DesktopWindow] = []
	for desktop_window in _programs_to_window.values():
		if desktop_window != null and is_instance_valid(desktop_window):
			windows.append(desktop_window)
	return windows


func _is_any_window_loading() -> bool:
	for desktop_window in _get_windows():
		if desktop_window.is_loading():
			return true
	return false


func _is_hovering_link() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered == null:
		return false
	return (
		hovered.get_cursor_shape(hovered.get_local_mouse_position()) == Control.CURSOR_POINTING_HAND
	)


func _is_hovering_text() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered is LineEdit or hovered is TextEdit


func _process(_delta: float) -> void:
	if _is_hovering_link():
		cursor.cursor_type = Cursor.CursorType.POINTER
	elif _is_hovering_text():
		cursor.cursor_type = Cursor.CursorType.TEXT
	elif _is_any_window_loading():
		cursor.cursor_type = Cursor.CursorType.BUSY
	else:
		cursor.cursor_type = Cursor.CursorType.ARROW
