class_name Desktop
extends Control

@export var programs: Array[Program]

var _programs_to_window: Dictionary[Program, DesktopWindow] = {}

@onready var icon_scene = preload("res://src/BrowserGame/Icon/icon.tscn")
@onready
var desktop_window_scene = preload("res://src/BrowserGame/DesktopWindow/desktop_window.tscn")
@onready var error_popup_scene = preload("res://src/BrowserGame/DesktopWindow/error_popup.tscn")


func _window_to_foreground(selected_window: DesktopWindow):
	%Windows.move_child(selected_window, get_child_count() - 1)


func _create_window(
	program: Program,
	app_scene: PackedScene = program.app_scene,
	callback: Callable = func(_node: Control): pass
) -> DesktopWindow:
	var desktop_window: DesktopWindow = desktop_window_scene.instantiate()
	desktop_window.content_scene = app_scene
	desktop_window.on_instantiate_callback = callback
	desktop_window.closed.connect(func(): _close_window(program))
	desktop_window.dragged.connect(_window_to_foreground)
	desktop_window.size = Vector2(800, 400)
	_programs_to_window.set(program, desktop_window)
	return desktop_window


func _create_error_popup(program: Program, error_message: String) -> DesktopWindow:
	var desktop_window = _create_window(
		program,
		error_popup_scene,
		func(error_popup: ErrorPopup): error_popup.error_message = error_message
	)
	desktop_window.size = Vector2(400, 200)
	return desktop_window


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
	else:
		_window_to_foreground(desktop_window)


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
		icon.double_clicked.connect(func(): _open_or_show_window(program))
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
