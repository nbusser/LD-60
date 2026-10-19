class_name ScoreScreen

extends Control

@onready
var level_label: Label = $CenterContainer/VBoxContainer/CenterContainer/HBoxContainer/LevelNumber
@onready
var coin_label: Label = $CenterContainer/VBoxContainer/CenterContainer2/HBoxContainer2/CoinsNumber
@onready var result_label: Label = $CenterContainer/VBoxContainer/Result


func _ready() -> void:
	# level 0 is Day 1
	level_label.text = str(GameState.current_level_number + 1)
	coin_label.text = "$%d" % GameState.money
	result_label.text = _result_text()


func _result_text() -> String:
	var hostage := GameState.hostage()
	if hostage == null:
		return "Pinny is proud of you."
	if GameState.is_alive(hostage):
		var ransom := GameState.level_state.level_data.ransom
		return "Ransom paid for %s: $%d" % [hostage.display_name, ransom]
	return "Pinny took everything. %s is gone." % hostage.display_name


func _on_NextLevelButton_pressed() -> void:
	Globals.end_scene(Globals.EndSceneStatus.SCORE_SCREEN_NEXT)
