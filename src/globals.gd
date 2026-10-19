extends Node

signal scene_ended(status: EndSceneStatus, params: Dictionary)
# Status sent along with signal end_scene()
enum EndSceneStatus {
	# Main meu
	MAIN_MENU_CLICK_START,
	MAIN_MENU_CLICK_SELECT_LEVEL,
	MAIN_MENU_CLICK_CREDITS,
	MAIN_MENU_CLICK_QUIT,
	# Level
	LEVEL_END,
	LEVEL_GAME_OVER,
	LEVEL_RESTART,
	# Game over screen
	GAME_OVER_RESTART,
	GAME_OVER_QUIT,
	# Score screen
	SCORE_SCREEN_NEXT,
	SCORE_SCREEN_RETRY,
	# Select level
	SELECT_LEVEL_SELECTED,
	SELECT_LEVEL_BACK,
	# Credits
	CREDITS_BACK,
	# Stats
	STATS_SCREEN_MENU,
}

const SAMPLE_GLOBAL_VARIABLE: int = 1

# In-game clipboard (the system clipboard is never used)
var clipboard := ""

var _cursor: Cursor


# Position of the fake cursor in global (canvas) coordinates
func get_cursor_position() -> Vector2:
	if _cursor != null and is_instance_valid(_cursor):
		return _cursor.get_global_cursor_position()
	return get_viewport().get_mouse_position()


func register_cursor(cursor: Cursor) -> void:
	_cursor = cursor


func unregister_cursor(cursor: Cursor) -> void:
	if _cursor == cursor:
		_cursor = null


func end_scene(status: EndSceneStatus, params: Dictionary = {}) -> void:
	scene_ended.emit(status, params)


func coin_flip() -> bool:
	return randi() % 2
