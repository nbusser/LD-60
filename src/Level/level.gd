class_name Level

extends Node

var level_state: LevelState

@onready var _browser := preload("res://src/BrowserGame/Browser/browser.tscn")


func _ready():
	assert(level_state, "init must be called before creating Level scene")

	# For this base project, we have two different games.
	var map: Node
	match self.level_state.level_data.type:
		LevelData.LevelType.BROWSER:
			var browser: BrowserGame = _browser.instantiate()
			browser.init(level_state.level_data)
			map = browser
		_:
			assert(false, "Invalid level type")
	add_child(map)

	$UI/Fadein.fade()


func init(level_data_p: LevelData):
	level_state = LevelState.new(level_data_p)
