class_name ScoreScreen

extends Control

@onready
var level_label: Label = $CenterContainer/VBoxContainer/CenterContainer/HBoxContainer/LevelNumber
@onready
var coin_label: Label = $CenterContainer/VBoxContainer/CenterContainer2/HBoxContainer2/CoinsNumber
@onready var result_label: Label = $CenterContainer/VBoxContainer/Result


func _ready() -> void:
	level_label.text = str(GameState.current_level_number + 1)
	coin_label.text = "$%d" % GameState.money
	result_label.text = _result_text()


func _result_text() -> String:
	var target := GameState.threatened_name()
	if GameState.last_day_success:
		return "Protection paid for %s: $%d" % [target, GameState.protection_fee]
	return "Pinny took everything. %s is gone." % target


func _on_NextLevelButton_pressed() -> void:
	Globals.end_scene(Globals.EndSceneStatus.SCORE_SCREEN_NEXT)
