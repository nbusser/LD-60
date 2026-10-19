class_name MessagePopup
extends Control

var message := ""
# Defaults to the error icon set in the scene
var icon: Texture2D


func _ready():
	%Label.text = message
	if icon != null:
		%Icon.texture = icon
