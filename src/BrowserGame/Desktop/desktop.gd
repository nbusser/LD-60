class_name Desktop
extends Control

@export var programs: Array[Program]

var _programs_to_window: Dictionary[Program, DesktopWindow] = {}

@onready var icon_scene = preload("res://src/BrowserGame/Icon/icon.tscn")
@onready
var desktop_window_scene = preload("res://src/BrowserGame/DesktopWindow/desktop_window.tscn")


func _open_or_show_window(program: Program):
	if program.app_scene == null:
		# TODO: use generic error window
		return

	var desktop_window: DesktopWindow = _programs_to_window.get(program)
	if desktop_window == null or not is_instance_valid(desktop_window):
		# Create the window
		desktop_window = desktop_window_scene.instantiate()
		desktop_window.content_scene = program.app_scene
		desktop_window.closed.connect(func(): _close_window(program))
		desktop_window.size = Vector2(800, 400)
		_programs_to_window.set(program, desktop_window)
		%Windows.add_child(desktop_window)
	else:
		# TODO: focus the window
		pass


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
		%Icons.add_child(icon)
