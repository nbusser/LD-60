extends Node

const CLICK = preload("res://assets/sounds/click.ogg")
const HARDDRIVE = preload("res://assets/sounds/harddrive.ogg")
const HARDDRIVE_SHORT = preload("res://assets/sounds/harddrive_short.ogg")
const MESSAGE = preload("res://assets/sounds/message.ogg")
const JUMP = preload("res://assets/sounds/jump.ogg")
const KILL = preload("res://assets/sounds/kill.ogg")
const PHOTO = preload("res://assets/sounds/photo0.ogg")
const SHUT_DOWN = preload("res://assets/sounds/shut_down.ogg")
const CORRECT = preload("res://assets/sounds/correct.ogg")
const WRONG = preload("res://assets/sounds/wrong.ogg")
const ERROR = preload("res://assets/sounds/error.ogg")
const NEW_REQUEST = preload("res://assets/sounds/new_request.ogg")

var _click_player := AudioStreamPlayer.new()
var _harddrive_player := AudioStreamPlayer.new()
var _harddrive_short_player := AudioStreamPlayer.new()
var _message_player := AudioStreamPlayer.new()
var _jump_player := AudioStreamPlayer.new()
var _kill_player := AudioStreamPlayer.new()
var _photo_player := AudioStreamPlayer.new()
var _shut_down_player := AudioStreamPlayer.new()
var _correct_player := AudioStreamPlayer.new()
var _wrong_player := AudioStreamPlayer.new()
var _error_player := AudioStreamPlayer.new()
var _new_request_player := AudioStreamPlayer.new()


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

	_shut_down_player.stream = SHUT_DOWN
	_shut_down_player.bus = &"SFX"
	add_child(_shut_down_player)

	_correct_player.stream = CORRECT
	_correct_player.bus = &"SFX"
	add_child(_correct_player)

	_wrong_player.stream = WRONG
	_wrong_player.bus = &"SFX"
	add_child(_wrong_player)

	_error_player.stream = ERROR
	_error_player.bus = &"SFX"
	add_child(_error_player)

	_new_request_player.stream = NEW_REQUEST
	_new_request_player.bus = &"SFX"
	add_child(_new_request_player)


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
	await _play_and_wait(_kill_player)


func play_photo() -> void:
	await _play_and_wait(_photo_player)


func play_shut_down() -> void:
	await _play_and_wait(_shut_down_player)


func play_correct() -> void:
	_correct_player.play()


func play_wrong() -> void:
	_wrong_player.play()


func play_error() -> void:
	_error_player.play()


func play_new_request() -> void:
	_new_request_player.play()


# Waits for the stream length: the finished signal is not always emitted
func _play_and_wait(player: AudioStreamPlayer) -> void:
	player.play()
	await get_tree().create_timer(player.stream.get_length()).timeout
