class_name Credits

extends Control

const CREDITS_PROGRAM: Program = preload("res://assets/data/program/credits.tres")

@onready var _windows: Control = $Windows
@onready var _desktop_window_scene := preload(
	"res://src/BrowserGame/DesktopWindow/desktop_window.tscn"
)


func _ready() -> void:
	var desktop_window: DesktopWindow = _desktop_window_scene.instantiate()
	desktop_window.window_title = CREDITS_PROGRAM.icon_label
	desktop_window.window_icon = CREDITS_PROGRAM.get_window_icon()
	desktop_window.content_scene = CREDITS_PROGRAM.app_scene
	desktop_window.closed.connect(_on_window_closed)
	_windows.add_child(desktop_window)
	_center_window(desktop_window)
	desktop_window.content_loaded.connect(_center_window.bind(desktop_window), CONNECT_ONE_SHOT)


func _center_window(desktop_window: DesktopWindow) -> void:
	desktop_window.position = ((size - desktop_window.size) / 2).floor()


func _on_window_closed() -> void:
	Sfx.click()
	Globals.end_scene(Globals.EndSceneStatus.CREDITS_BACK)
