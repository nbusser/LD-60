class_name Level

extends Node

var level_state: LevelState

@onready var hud: HUD = $UI/HUD
@onready var timer: Timer = $Timer

@onready var _tilemap_example_map := preload("res://src/TilemapGame/Map/map.tscn")
@onready var _platformer_example_map := preload("res://src/PlatformerGame/Map/map.tscn")


func _ready():
	assert(level_state, "init must be called before creating Level scene")

	# For this base project, we have two different games.
	var map: Node2D
	match self.level_state.level_data.type:
		LevelData.LevelType.TILEMAP_EXAMPLE:
			map = _tilemap_example_map.instantiate()
		LevelData.LevelType.PLATFORMER_EXAMPLE:
			map = _platformer_example_map.instantiate()
		_:
			assert(false, "Invalid level type")
	add_child(map)

	hud.init(level_state)

	$UI/Fadein.fade()


func init(level_data_p: LevelData):
	level_state = LevelState.new(level_data_p)


func _on_Timer_timeout():
	# Simulates game state change
	level_state.nb_coins += randi() % 100

	await $UI/Fadeout.fade()

	if randi() % 4:
		Globals.end_scene(Globals.EndSceneStatus.LEVEL_GAME_OVER)
	else:
		Globals.end_scene(Globals.EndSceneStatus.LEVEL_END, {"new_nb_coins": level_state.nb_coins})
