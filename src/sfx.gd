extends Node

const CLICK = preload("res://assets/sounds/click.ogg")
const HARDDRIVE = preload("res://assets/sounds/harddrive.ogg")
const HARDDRIVE_SHORT = preload("res://assets/sounds/harddrive_short.ogg")
const MESSAGE = preload("res://assets/sounds/message.ogg")
const JUMP = preload("res://assets/sounds/jump.ogg")
const KILL = preload("res://assets/sounds/kill.ogg")
const PHOTO = preload("res://assets/sounds/photo0.ogg")

var _click_player := AudioStreamPlayer.new()
var _harddrive_player := AudioStreamPlayer.new()
var _harddrive_short_player := AudioStreamPlayer.new()
var _message_player := AudioStreamPlayer.new()
var _jump_player := AudioStreamPlayer.new()
var _kill_player := AudioStreamPlayer.new()
var _photo_player := AudioStreamPlayer.new()


func _ready() -> void:
	_click_player.stream = CLICK
	_click_player.bus = &"SFX"
	add_child(_click_player)

	_harddrive_player.stream = HARDDRIVE
	_harddrive_player.bus = &"SFX"
	add_child(_harddrive_player)

	_harddrive_short_player.stream = HARDDRIVE_SHORT
	_harddrive_short_player.bus = &"SFX"
	add_child(_harddrive_short_player)

	_message_player.stream = MESSAGE
	_message_player.bus = &"SFX"
	add_child(_message_player)

	_jump_player.stream = JUMP
	_jump_player.bus = &"SFX"
	add_child(_jump_player)

	_kill_player.stream = KILL
	_kill_player.bus = &"SFX"
	add_child(_kill_player)

	_photo_player.stream = PHOTO
	_photo_player.bus = &"SFX"
	add_child(_photo_player)


func click() -> void:
	_click_player.play()


func play_harddrive() -> void:
	_harddrive_player.play()


func stop_harddrive() -> void:
	_harddrive_player.stop()


func play_harddrive_short() -> void:
	_harddrive_short_player.play()


func play_message() -> void:
	_message_player.play()


func play_jump() -> void:
	_jump_player.play()


func play_kill() -> void:
	_kill_player.play()
	await _kill_player.finished


func play_photo() -> void:
	_photo_player.play()
	await _photo_player.finished
