class_name DesktopWindow
extends Control

signal closed

@export var content_scene: PackedScene


func _ready():
	var content = content_scene.instantiate()
	assert(content is Control)
	%Content.add_child(content)


func _on_close_button_pressed() -> void:
	emit_signal("closed")

# TODO: drag
