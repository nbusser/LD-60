class_name Program
extends Resource

@export var id: String
@export var icon_texture: Texture2D
## Optional 16x16 icon for window title bars and task bar buttons.
## Falls back to icon_texture when empty.
@export var icon_texture_16: Texture2D
@export var icon_label: String

@export var app_scene: PackedScene


func get_window_icon() -> Texture2D:
	return icon_texture_16 if icon_texture_16 != null else icon_texture
