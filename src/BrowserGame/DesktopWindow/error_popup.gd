class_name ErrorPopup
extends Control

var error_message := "error"


func _ready():
	%Label.text = error_message
