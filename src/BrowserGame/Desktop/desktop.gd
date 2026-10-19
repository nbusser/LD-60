class_name Desktop
extends Control

signal program_opened(program_id: String)

const IMAGE_WINDOW_ICON_16 := preload(
	"res://assets/sprites/icons/serenity/16x16/filetype-image.png"
)
const SEARCH_PROGRAM_PATH := "res://assets/data/program/search.tres"
const COFFEE_MACHINE_PROGRAM_PATH := "res://assets/data/program/coffee_machine.tres"

@export var programs: Array[Program]
# The player can't open programs, e.g. during a cutscene
var locked := false

var _programs_to_window: Dictionary[Program, DesktopWindow] = {}
var _window_to_task_button: Dictionary[DesktopWindow, TaskButton] = {}
var _program_to_icon: Dictionary[Program, Icon] = {}
var _image_programs: Dictionary[String, Program] = {}
var _is_selecting := false
var _selection_origin := Vector2.ZERO
var _selection_base: Array[Icon] = []
var _search_program: Program
var _coffee_machine_program: Program

@onready var icon_scene = preload("res://src/BrowserGame/Icon/icon.tscn")
@onready
var desktop_window_scene = preload("res://src/BrowserGame/DesktopWindow/desktop_window.tscn")
@onready var message_popup_scene = preload("res://src/BrowserGame/DesktopWindow/message_popup.tscn")
@onready var task_button_scene = preload("res://src/BrowserGame/Desktop/TaskButton.tscn")
@onready var cursor_popup_scene = preload("res://src/BrowserGame/Desktop/cursor_popup.tscn")
@onready var image_viewer_scene = preload("res://src/Family/image_viewer.tscn")
@onready var credits_program: Program = preload("res://assets/data/program/credits.tres")
@onready var cursor = $Cursor
@onready var pinny: Pinny = %Pinny
@onready var _clock_label: Label = %ClockLabel
@onready var _money_label: Label = %MoneyLabel
@onready var _selection_rect: DesktopSelectionRect = %SelectionRect
@onready var _pause_menu: PauseMenu = %PauseMenu


# Desktop containing the given node, if any
static func find_from(node: Node) -> Desktop:
	while node != null and not node is Desktop:
		node = node.get_parent()
	return node as Desktop


# Show a short message above the cursor (e.g. "Copied")
func show_cursor_popup(text: String) -> void:
	var popup: CursorPopup = cursor_popup_scene.instantiate()
	popup.text = text
	add_child(popup)
	# keep the fake cursor drawn on top of the popup
	move_child(popup, cursor.get_index())


# Add a program that is not on the desktop by default (e.g. a gift from Pinny)
func add_program(program: Program) -> void:
	if programs.has(program):
		return
	# don't modify the exported array, it may be shared with other desktops
	programs = programs.duplicate()
	programs.append(program)
	_programs_to_window.set(program, null)
	_create_icon(program)


# Remove a program from the desktop, closing its window
func remove_program(program: Program) -> void:
	var desktop_window: DesktopWindow = _programs_to_window.get(program)
	if desktop_window != null and is_instance_valid(desktop_window):
		_remove_task_button(desktop_window)
		desktop_window.queue_free()
	_remove_icon(program)
	_programs_to_window.erase(program)
	programs = programs.duplicate()
	programs.erase(program)


func _spawn_credits() -> void:
	add_program(credits_program)


func _on_upgrades_changed() -> void:
	# Plain teal until the wallpaper is bought
	%BackgroundImage.visible = GameState.is_upgrade_owned("wallpaper")
	if GameState.is_upgrade_owned("search"):
		if _search_program == null:
			_search_program = load(SEARCH_PROGRAM_PATH)
		add_program(_search_program)
	if GameState.is_upgrade_owned("coffee_machine"):
		if _coffee_machine_program == null:
			_coffee_machine_program = load(COFFEE_MACHINE_PROGRAM_PATH)
		add_program(_coffee_machine_program)


# Hide every icon, they come back one by one with reveal_next_icon()
func hide_icons() -> void:
	for icon in %Icons.get_children():
		icon.visible = false


func show_icons() -> void:
	for icon in %Icons.get_children():
		icon.visible = true


func reveal_next_icon() -> void:
	for icon in %Icons.get_children():
		if not icon.visible:
			icon.visible = true
			return


# Open a window showing the given image in large
func show_image(title: String, texture: Texture2D) -> void:
	var program: Program = _image_programs.get(title)
	if program == null:
		program = Program.new()
		program.icon_label = title
		program.icon_texture = texture
		program.icon_texture_16 = IMAGE_WINDOW_ICON_16
		program.app_scene = image_viewer_scene
		_image_programs[title] = program
	_open_or_show_window(program, func(viewer: TextureRect): viewer.texture = texture)
	Sfx.click()


# Open a popup showing the message, returns once the player closes it
func show_popup(
	title: String, message: String, icon: Texture2D, window_icon_16: Texture2D = null
) -> void:
	var program := Program.new()
	program.icon_label = title
	program.icon_texture = icon
	program.icon_texture_16 = window_icon_16
	program.app_scene = message_popup_scene
	_open_or_show_window(
		program,
		func(popup: MessagePopup):
			popup.message = message
			popup.icon = icon
	)

	var desktop_window: DesktopWindow = _programs_to_window[program]
	print(
		(
			"[DEBUG day-end] popup window: inside_tree=%s visible=%s pos=%s size=%s"
			% [
				desktop_window.is_inside_tree(),
				desktop_window.is_visible_in_tree(),
				desktop_window.global_position,
				desktop_window.size
			]
		)
	)
	desktop_window.content_loaded.connect(
		func(): print("[DEBUG day-end] popup loaded at %s" % desktop_window.global_position),
		CONNECT_ONE_SHOT
	)
	await desktop_window.closed
	_programs_to_window.erase(program)
	desktop_window.queue_free()


func close_all_windows() -> void:
	for program in _programs_to_window.keys():
		_close_window(program)


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
		if not _is_icon(hovered) and not _is_additive_select_pressed():
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


func _on_pause_button_pressed() -> void:
	if _pause_menu.visible:
		return
	Sfx.click()
	_pause_menu.open()


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
	desktop_window.window_icon = program.get_window_icon()
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
		message_popup_scene,
		func(error_popup: MessagePopup): error_popup.message = error_message
	)
	return desktop_window


func _center_window(desktop_window: DesktopWindow) -> void:
	desktop_window.position = ((size - desktop_window.size) / 2).floor()


func _open_or_show_window(program: Program, callback: Callable = func(_node: Control): pass):
	_unselect_icons()
	var desktop_window: DesktopWindow = _programs_to_window.get(program)
	if desktop_window == null or not is_instance_valid(desktop_window):
		# Create the window
		if program.app_scene != null:
			desktop_window = _create_window(program, program.app_scene, callback)
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

	program_opened.emit(program.id)


# A program is running while its window is open, even if minimized
func is_program_running(program_id: String) -> bool:
	for program in programs:
		if program.id == program_id:
			var desktop_window: DesktopWindow = _programs_to_window.get(program)
			return _window_to_task_button.has(desktop_window)
	return false


func _close_window(program: Program):
	var desktop_window: DesktopWindow = _programs_to_window.get(program)
	if desktop_window != null and is_instance_valid(desktop_window):
		_remove_task_button(desktop_window)
		desktop_window.visible = false
	_update_task_buttons()


func _ready() -> void:
	for program in programs:
		_programs_to_window.set(program, null)
		_create_icon(program)

	GameState.money_changed.connect(_on_money_changed)
	_on_money_changed(GameState.money)
	GameState.upgrades_changed.connect(_on_upgrades_changed)
	_on_upgrades_changed()
	Globals.credits_restored.connect(_spawn_credits)


func _create_icon(program: Program) -> void:
	if _program_to_icon.has(program):
		return

	var icon: Icon = icon_scene.instantiate()
	icon.text = program.icon_label
	icon.texture_normal = program.icon_texture
	icon.double_clicked.connect(
		func():
			# programs can't be opened while the setup is installing
			if locked or _is_any_window_busy():
				return
			_open_or_show_window(program)
			Sfx.click()
	)
	# On icon selected, un-select all other icons unless selecting additively
	icon.selected.connect(_on_icon_selected)
	%Icons.add_child(icon)
	_program_to_icon[program] = icon


func _remove_icon(program: Program) -> void:
	var icon: Icon = _program_to_icon.get(program)
	if icon != null and is_instance_valid(icon):
		%Icons.remove_child(icon)
		icon.queue_free()
	_program_to_icon.erase(program)


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
		_start_selection()


func _start_selection() -> void:
	_is_selecting = true
	_selection_origin = _clamp_to_window_area(_selection_rect.get_local_mouse_position())
	if not _is_additive_select_pressed():
		_unselect_icons()
	_selection_base = _get_selected_icons()
	_selection_rect.clear()


func _update_selection_rect() -> void:
	if not _is_selecting:
		return
	var current := _clamp_to_window_area(_selection_rect.get_local_mouse_position())
	var rect := Rect2(_selection_origin, Vector2.ZERO).expand(current)
	_selection_rect.selection_rect = rect
	_apply_selection_rect(rect)


# Select every icon touched by the rectangle, on top of the selection that was
# already active when the drag started.
func _apply_selection_rect(rect: Rect2) -> void:
	var global_rect := Rect2(_selection_rect.global_position + rect.position, rect.size)
	for icon in %Icons.get_children():
		if icon is Icon:
			icon.is_selected = (
				_selection_base.has(icon) or global_rect.intersects(icon.get_global_rect())
			)


func _end_selection() -> void:
	_update_selection_rect()
	_is_selecting = false
	_selection_rect.clear()
	_selection_base.clear()


func _on_icon_selected(selected_icon: Icon) -> void:
	var toggle := Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META)
	var additive := toggle or Input.is_key_pressed(KEY_SHIFT)
	if not additive:
		_unselect_icons()

	if toggle and selected_icon.is_selected:
		selected_icon.is_selected = false
	else:
		selected_icon.is_selected = true


func _is_additive_select_pressed() -> bool:
	return (
		Input.is_key_pressed(KEY_CTRL)
		or Input.is_key_pressed(KEY_META)
		or Input.is_key_pressed(KEY_SHIFT)
	)


func _get_selected_icons() -> Array[Icon]:
	var selected: Array[Icon] = []
	for icon in %Icons.get_children():
		if icon is Icon and icon.is_selected:
			selected.append(icon)
	return selected


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
