class_name Icon
extends Control

@export var texture: Texture2D
@export var text: String


func _ready():
	$Texture.texture = texture
	$Label.text = text

# TODO click
