class_name DesktopWindow
extends Control

signal closed

@export var content_scene: PackedScene


func ready():
	var content = content_scene.instantiate()
	assert(content is Control)
	$VBoxContainer.add_child(content)


func _on_close_button_pressed() -> void:
	emit_signal("closed")

# TODO: drag
