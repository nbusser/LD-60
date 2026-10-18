extends Node

const CLICK = preload("res://assets/sounds/click.ogg")

var _click_player := AudioStreamPlayer.new()


func _ready() -> void:
	_click_player.stream = CLICK
	_click_player.bus = &"SFX"
	add_child(_click_player)


func click() -> void:
	_click_player.play()
