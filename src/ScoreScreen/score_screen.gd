class_name ScoreScreen

extends Control

const LAST_RANSOM_LEVEL := 4

@onready
var level_label: Label = $CenterContainer/VBoxContainer/CenterContainer/HBoxContainer/LevelNumber
@onready
var coin_label: Label = $CenterContainer/VBoxContainer/CenterContainer2/HBoxContainer2/CoinsNumber
@onready var result_label: Label = $CenterContainer/VBoxContainer/Result
@onready var _entries: HBoxContainer = %Entries


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
	else:
		result_label.hide()

	for i in GameState.FAMILY.size():
		var member := GameState.FAMILY[i]
		var photo: TextureRect = _entries.get_child(i)
		photo.texture = (
			member.portrait if GameState.is_alive(member) else member.portrait_terminated
		)


func _final_text() -> String:
	match GameState.total_death():
		0:
			return "TODO: whole family saved"
		1:
			return "TODO: one dead"
		2:
			return "TODO: two dead"
		3:
			return "TODO: three dead"
		_:
			return "TODO: whole family dead"


func _on_NextLevelButton_pressed() -> void:
	Globals.end_scene(Globals.EndSceneStatus.SCORE_SCREEN_NEXT)
