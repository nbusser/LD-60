class_name Level

extends Node

var level_state: LevelState

@onready var _desktop := preload("res://src/BrowserGame/Desktop/desktop.tscn")


func _ready():
	assert(level_state, "init must be called before creating Level scene")

	# For this base project, we have two different games.
	var map: Control
	match self.level_state.level_data.type:
		LevelData.LevelType.BROWSER:
			map = _desktop.instantiate()
		_:
			assert(false, "Invalid level type")
	add_child(map)

	$UI/Fadein.fade()


func init(level_data_p: LevelData):
	level_state = LevelState.new(level_data_p)
