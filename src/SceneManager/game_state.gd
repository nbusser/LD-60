extends Node

var current_level_number := 0
var nb_coins := 0
var level_state: LevelState


func reset() -> void:
	current_level_number = 0
	nb_coins = 0
	level_state = null
