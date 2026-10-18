class_name Pinny
extends Node2D

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _label: Label = $Body/Message/MarginContainer/Label


func appear(text: String) -> void:
	_label.text = text
	_animation_player.play("appear")
	await _animation_player.animation_finished
