class_name Pinny
extends Node2D

signal page_ended

enum Mood { NEUTRAL, ANGRY, LAUGH }

const _MOOD_ANIMATIONS: Dictionary[Mood, StringName] = {
	Mood.NEUTRAL: &"default",
	Mood.ANGRY: &"angry",
	Mood.LAUGH: &"laugh",
}

const MESSAGE_BLINK_COUNT := 2
const MESSAGE_BLINK_INTERVAL := 0.08
# Speeds up the walk in and out of the screen
const WALK_SPEED := 1.35

# Determines how long a msg stays on screen
@export var seconds_per_character := 0.06
@export var min_page_duration := 3.5

# If pinny is already on screen
var is_present := false

# Increments on every say()
# Allows to properly skip all pages if two say() are called closely
var _talk_id := 0
# True while a page waits for its timer or a click to go to the next one
var _is_waiting_page := false

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _sprite: AnimatedSprite2D = $Body/Sprite2D
@onready var _message: Control = $Body/MessageArea/Message
@onready var _label: Label = $Body/MessageArea/Message/MarginContainer/Label


func _ready() -> void:
	_message.gui_input.connect(_on_message_gui_input)


func visit(pages: Array[String], mood: Mood = Mood.NEUTRAL) -> void:
	await appear()
	await say(pages, mood)
	await leave()


func appear() -> void:
	if is_present:
		return
	is_present = true
	await _play_animation(&"appear")
	_sprite.play(_MOOD_ANIMATIONS[Mood.NEUTRAL])


# With hold, the last page stays on screen until the next say() or leave()
func say(pages: Array[String], mood: Mood = Mood.NEUTRAL, hold := false) -> void:
	_talk_id += 1
	var talk_id := _talk_id
	_sprite.play(_MOOD_ANIMATIONS[mood])
	_message.visible = true
	for i in pages.size():
		var page := pages[i]
		_label.text = page
		Sfx.play_message()
		_blink_message(talk_id)
		if hold and i == pages.size() - 1:
			return
		await _wait_page(_page_duration(page))
		# A new say() has been called. Skip other pages
		if talk_id != _talk_id:
			return
	_message.visible = false
	_sprite.play(_MOOD_ANIMATIONS[Mood.NEUTRAL])


# Keeps the instruction on screen until it is done
func instruct(pages: Array[String], is_done: Callable, changed: Signal) -> void:
	say(pages, Mood.NEUTRAL, true)
	while not is_done.call():
		await changed


func leave() -> void:
	if not is_present:
		return
	_talk_id += 1
	_message.visible = false
	await _play_animation(&"leave")
	_sprite.stop()
	is_present = false


# Waits for the animation length: animation_finished may not be emitted
func _play_animation(animation: StringName) -> void:
	_animation_player.play(animation, -1, WALK_SPEED)
	_play_move()
	var duration := _animation_player.get_animation(animation).length / WALK_SPEED
	await get_tree().create_timer(duration).timeout


func _play_move() -> void:
	_sprite.play(&"move_in", WALK_SPEED)
	await _sprite.animation_finished
	_sprite.play(&"move_loop", WALK_SPEED)
	Sfx.play_jump()
	await get_tree().create_timer(_animation_duration(&"move_loop") / WALK_SPEED).timeout
	_sprite.play(&"move_out", WALK_SPEED)
	Sfx.play_jump()
	await _sprite.animation_finished


func _blink_message(talk_id: int) -> void:
	_message.visible = true
	await get_tree().create_timer(MESSAGE_BLINK_INTERVAL).timeout
	for _i in MESSAGE_BLINK_COUNT:
		if talk_id != _talk_id:
			return
		_message.visible = false
		await get_tree().create_timer(MESSAGE_BLINK_INTERVAL).timeout
		if talk_id != _talk_id:
			return
		_message.visible = true
		await get_tree().create_timer(MESSAGE_BLINK_INTERVAL).timeout


# Ends on the timer or when the player clicks the message
func _wait_page(duration: float) -> void:
	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(page_ended.emit)
	_is_waiting_page = true
	await page_ended
	_is_waiting_page = false
	# A skipped page timer must not end the next page
	if timer.timeout.is_connected(page_ended.emit):
		timer.timeout.disconnect(page_ended.emit)


func _on_message_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if not mouse_event or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not _is_waiting_page:
		return
	Sfx.click()
	page_ended.emit()


func _animation_duration(animation: StringName) -> float:
	var frames := _sprite.sprite_frames
	return frames.get_frame_count(animation) / frames.get_animation_speed(animation)


func _page_duration(page: String) -> float:
	return maxf(min_page_duration, page.length() * seconds_per_character)
