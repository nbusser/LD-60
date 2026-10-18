class_name Pinny
extends Node2D

enum Mood { NEUTRAL, ANGRY, LAUGH }

const _MOOD_ANIMATIONS: Dictionary[Mood, StringName] = {
	Mood.NEUTRAL: &"default",
	Mood.ANGRY: &"angry",
	Mood.LAUGH: &"laugh",
}

# Determines how long a msg stays on screen
@export var seconds_per_character := 0.06
@export var min_page_duration := 2.0

# If pinny is already on screen
var is_present := false

# Increments on every say()
# Allows to properly skip all pages if two say() are called closely
var _talk_id := 0

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _sprite: AnimatedSprite2D = $Body/Sprite2D
@onready var _message: Control = $Body/Message
@onready var _label: Label = $Body/Message/MarginContainer/Label


func visit(pages: Array[String], mood: Mood = Mood.NEUTRAL) -> void:
	await appear()
	await say(pages, mood)
	await leave()


func appear() -> void:
	if is_present:
		return
	is_present = true
	_animation_player.play("appear")
	_play_move()
	await _animation_player.animation_finished
	_sprite.play(_MOOD_ANIMATIONS[Mood.NEUTRAL])


func say(pages: Array[String], mood: Mood = Mood.NEUTRAL) -> void:
	_talk_id += 1
	var talk_id := _talk_id
	_sprite.play(_MOOD_ANIMATIONS[mood])
	_message.visible = true
	for page: String in pages:
		_label.text = page
		await get_tree().create_timer(_page_duration(page)).timeout
		# A new say() has been called. Skip other pages
		if talk_id != _talk_id:
			return
	_message.visible = false
	_sprite.play(_MOOD_ANIMATIONS[Mood.NEUTRAL])


func leave() -> void:
	if not is_present:
		return
	_talk_id += 1
	_message.visible = false
	_animation_player.play("leave")
	_play_move()
	await _animation_player.animation_finished
	_sprite.stop()
	is_present = false


func _play_move() -> void:
	_sprite.play(&"move_in")
	await _sprite.animation_finished
	_sprite.play(&"move_loop")
	await get_tree().create_timer(_animation_duration(&"move_loop")).timeout
	_sprite.play(&"move_out")
	await _sprite.animation_finished


func _animation_duration(animation: StringName) -> float:
	var frames := _sprite.sprite_frames
	return frames.get_frame_count(animation) / frames.get_animation_speed(animation)


func _page_duration(page: String) -> float:
	return maxf(min_page_duration, page.length() * seconds_per_character)
