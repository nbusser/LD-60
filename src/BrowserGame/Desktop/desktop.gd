class_name Desktop
extends Control

const SETUP_PROGRAM_ID := "setup"

@export var programs: Array[Program]

var _programs_to_window: Dictionary[Program, DesktopWindow] = {}
var _window_to_task_button: Dictionary[DesktopWindow, TaskButton] = {}
var _program_to_icon: Dictionary[Program, Icon] = {}
var _setup_program: Program
var _is_selecting := false
var _selection_origin := Vector2.ZERO

@onready var icon_scene = preload("res://src/BrowserGame/Icon/icon.tscn")
@onready
var desktop_window_scene = preload("res://src/BrowserGame/DesktopWindow/desktop_window.tscn")
@onready var error_popup_scene = preload("res://src/BrowserGame/DesktopWindow/error_popup.tscn")
@onready var task_button_scene = preload("res://src/BrowserGame/Desktop/TaskButton.tscn")
@onready var cursor = $Cursor
@onready var pinny: Pinny = %Pinny
@onready var _clock_label: Label = %ClockLabel
@onready var _money_label: Label = %MoneyLabel
@onready var _selection_rect: DesktopSelectionRect = %SelectionRect


func _window_to_foreground(selected_window: DesktopWindow):
	_unselect_icons()
	%Windows.move_child(selected_window, -1)
	_update_task_buttons()


func _input(event: InputEvent) -> void:
	if _is_selecting:
		if event is InputEventMouseMotion:
			_update_selection_rect()
			return
		if (
			event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and not event.pressed
		):
			_end_selection()
			return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hovered := get_viewport().gui_get_hovered_control()
		var node: Node = hovered
		while node != null:
			var desktop_window := node as DesktopWindow
			if desktop_window != null:
				_window_to_foreground(desktop_window)
				return
			node = node.get_parent()
		if not _is_icon(hovered):
			_unselect_icons()


func _create_task_button(desktop_window: DesktopWindow) -> void:
	var task_button: TaskButton = task_button_scene.instantiate()
	task_button.window_title = desktop_window.window_title
	task_button.window_icon = desktop_window.window_icon
	task_button.pressed.connect(_on_task_button_pressed.bind(desktop_window))
	%Tasks.add_child(task_button)
	_window_to_task_button.set(desktop_window, task_button)


func _remove_task_button(desktop_window: DesktopWindow) -> void:
	var task_button: TaskButton = _window_to_task_button.get(desktop_window)
	if task_button != null and is_instance_valid(task_button):
		%Tasks.remove_child(task_button)
		task_button.queue_free()
	_window_to_task_button.erase(desktop_window)


func _get_active_window() -> DesktopWindow:
	var active_window: DesktopWindow = null
	for child in %Windows.get_children():
		var desktop_window := child as DesktopWindow
		if (
			desktop_window != null
			and desktop_window.visible
			and not desktop_window.is_queued_for_deletion()
		):
			active_window = desktop_window
	return active_window


func _update_task_buttons() -> void:
	var active_window := _get_active_window()
	for desktop_window in _get_windows():
		var task_button: TaskButton = _window_to_task_button.get(desktop_window)
		if is_instance_valid(task_button):
			task_button.button_pressed = desktop_window == active_window
		desktop_window.set_focused(desktop_window == active_window)


func _on_task_button_pressed(desktop_window: DesktopWindow) -> void:
	if not is_instance_valid(desktop_window):
		return

	if desktop_window == _get_active_window():
		desktop_window.visible = false
		_update_task_buttons()
	else:
		desktop_window.visible = true
		_window_to_foreground(desktop_window)

	Sfx.click()


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
	_unselect_icons()
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
		_create_task_button(desktop_window)
		_update_task_buttons()

		# center window again once loaded
		desktop_window.content_loaded.connect(_center_window.bind(desktop_window), CONNECT_ONE_SHOT)
	else:
		if not _window_to_task_button.has(desktop_window):
			_create_task_button(desktop_window)
		desktop_window.visible = true
		_window_to_foreground(desktop_window)
		# Reset window position
		_center_window(desktop_window)


func _close_window(program: Program):
	var desktop_window: DesktopWindow = _programs_to_window.get(program)
	if desktop_window != null and is_instance_valid(desktop_window):
		_remove_task_button(desktop_window)
		desktop_window.visible = false
	_update_task_buttons()


func _ready() -> void:
	for program in programs:
		_programs_to_window.set(program, null)
		if program.id == SETUP_PROGRAM_ID:
			_setup_program = program

	_refresh_icons()
	GameState.setup_completed.connect(_on_setup_completed)
	GameState.setup_program_revealed.connect(_refresh_icons)
	GameState.money_changed.connect(_on_money_changed)
	_on_money_changed(GameState.money)


func _refresh_icons() -> void:
	var setup_done := not GameState.needs_setup()
	var reveal_count := GameState.revealed_setup_program_count

	if _setup_program != null:
		if setup_done:
			_remove_icon(_setup_program)
		else:
			_create_icon(_setup_program)

	var reveal_index := 0
	for program in programs:
		if program == _setup_program:
			continue
		if setup_done or reveal_index < reveal_count:
			_create_icon(program)
		reveal_index += 1

	# keep the Setup icon last while installing
	if not setup_done and _setup_program != null:
		var setup_icon: Icon = _program_to_icon.get(_setup_program)
		if setup_icon != null:
			%Icons.move_child(setup_icon, -1)


func _create_icon(program: Program) -> void:
	if _program_to_icon.has(program):
		return

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
	_program_to_icon[program] = icon


func _remove_icon(program: Program) -> void:
	var icon: Icon = _program_to_icon.get(program)
	if icon != null and is_instance_valid(icon):
		%Icons.remove_child(icon)
		icon.queue_free()
	_program_to_icon.erase(program)


func _on_setup_completed() -> void:
	_refresh_icons()


func set_clock(hour: int, minute: int) -> void:
	_clock_label.text = "%02d:%02d" % [hour, minute]


# Area of the desktop not covered by the task bar, in global coordinates.
func get_window_area() -> Rect2:
	var task_bar := $TaskBar as Control
	var top_left := global_position
	return Rect2(top_left, Vector2(size.x, task_bar.global_position.y - top_left.y))


func _on_money_changed(value: int) -> void:
	_money_label.text = "$%d" % value


func _on_background_color_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_unselect_icons()
		_start_selection()


func _start_selection() -> void:
	_is_selecting = true
	_selection_origin = _clamp_to_window_area(_selection_rect.get_local_mouse_position())
	_selection_rect.clear()


func _update_selection_rect() -> void:
	if not _is_selecting:
		return
	var current := _clamp_to_window_area(_selection_rect.get_local_mouse_position())
	_selection_rect.selection_rect = Rect2(_selection_origin, Vector2.ZERO).expand(current)


func _end_selection() -> void:
	_is_selecting = false
	_selection_rect.clear()


func _clamp_to_window_area(point: Vector2) -> Vector2:
	var task_bar := $TaskBar as Control
	var area := Rect2(Vector2.ZERO, Vector2(size.x, task_bar.position.y))
	return point.clamp(area.position, area.position + area.size)


func _is_icon(node: Node) -> bool:
	while node != null:
		if node is Icon:
			return true
		node = node.get_parent()
	return false


func _unselect_icons() -> void:
	for icon in %Icons.get_children():
		icon.is_selected = false


func _get_windows() -> Array[DesktopWindow]:
	var windows: Array[DesktopWindow] = []
	for desktop_window in _programs_to_window.values():
		if desktop_window != null and is_instance_valid(desktop_window):
			windows.append(desktop_window)
	return windows


func _is_any_window_busy() -> bool:
	for desktop_window in _get_windows():
		if desktop_window.is_busy():
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
	if _is_any_window_busy():
		cursor.cursor_type = Cursor.CursorType.BUSY
	elif _is_hovering_link():
		cursor.cursor_type = Cursor.CursorType.POINTER
	elif _is_hovering_text():
		cursor.cursor_type = Cursor.CursorType.TEXT
	else:
		cursor.cursor_type = Cursor.CursorType.ARROW
