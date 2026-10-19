extends Node

const CLICK = preload("res://assets/sounds/click.ogg")
const HARDDRIVE = preload("res://assets/sounds/harddrive.ogg")

var _click_player := AudioStreamPlayer.new()
var _harddrive_player := AudioStreamPlayer.new()


func _ready() -> void:
	_click_player.stream = CLICK
	_click_player.bus = &"SFX"
	add_child(_click_player)

	_harddrive_player.stream = HARDDRIVE
	_harddrive_player.bus = &"SFX"
	add_child(_harddrive_player)


func click() -> void:
	_click_player.play()


func play_harddrive() -> void:
	_harddrive_player.play()


func stop_harddrive() -> void:
	_harddrive_player.stop()
