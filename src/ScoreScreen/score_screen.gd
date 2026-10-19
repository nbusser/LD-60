class_name ScoreScreen

extends Control

const LAST_RANSOM_LEVEL := 5

@onready
var level_label: Label = $CenterContainer/VBoxContainer/CenterContainer/HBoxContainer/LevelNumber
@onready
var coin_label: Label = $CenterContainer/VBoxContainer/CenterContainer2/HBoxContainer2/CoinsNumber
@onready var result_label: Label = $CenterContainer/VBoxContainer/Result
@onready var _entries: HBoxContainer = %Entries
@onready var _next_button: Button = $CenterContainer/VBoxContainer/CenterContainer3/NextLevelButton


func _ready() -> void:
	level_label.text = str(GameState.current_level_number + 1)
	coin_label.text = "$%d" % GameState.money

	# Day 1 is the tutorial, Pinny holds nobody yet
	if GameState.current_level_number == 0:
		_entries.hide()
		return

	# Day 5 is the last ransom, its result depends on the whole family
	if GameState.current_level_number == LAST_RANSOM_LEVEL:
		result_label.text = _final_text()
		# Last day, the game ends on the credits
		_next_button.text = "Credits"
	else:
		result_label.hide()

	for i in GameState.FAMILY.size():
		var member := GameState.FAMILY[i]
		var photo: TextureRect = _entries.get_child(i)
		photo.texture = (
			member.portrait if GameState.is_alive(member) else member.portrait_terminated
		)


func _final_text() -> String:
	if GameState.is_player_dead:
		match GameState.total_death():
			0:
				return "You saved your whole family but you could not make it. You will be remembered."
			4:
				return "You and your whole family did not survive Youpi and Pinny."
			_:
				return "You sacrificed yourself to saved who you could save. You will be remembered."

	match GameState.total_death():
		0:
			return "You saved your family and your ass from Youpi and Pinny. His manager will hear from him."
		4:
			return "You escaped Youpi, but sadly your whole family died to the pin of Pinny."
		_:
			return "You could not save everyone and will have remorse."


func _on_NextLevelButton_pressed() -> void:
	Globals.end_scene(Globals.EndSceneStatus.SCORE_SCREEN_NEXT)
