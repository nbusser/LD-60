class_name SceneManager

extends Control

# Settings of all levels. To be configured from the editor
@export var levels: Array[LevelData]
@export var debug_only_start_level: int = 0

var current_audio_player: AudioStreamPlayer

var current_scene:
	set = set_scene

@onready var music_players := $Musics.get_children()

@onready var main_menu := preload("res://src/MainMenu/main_menu.tscn")
@onready var level := preload("res://src/Level/level.tscn")
@onready var score_screen := preload("res://src/ScoreScreen/score_screen.tscn")
@onready var level_selector := preload("res://src/LevelSelector/level_selector.tscn")
@onready var credits := preload("res://src/Credits/credits.tscn")
@onready var game_over := preload("res://src/GameOver/game_over.tscn")
@onready var stats_screen := preload("res://src/StatsScreen/stats_screen.tscn")

@onready var viewport: Viewport = $SubViewportContainer/SubViewport
@onready var _ambience_player: AudioStreamPlayer = $Ambience/Brouhaha


func set_scene(new_scene: Node) -> void:
	# Free older scene
	if current_scene:
		viewport.remove_child(current_scene)
		current_scene.queue_free()

	current_scene = new_scene
	viewport.add_child(current_scene)


func _ready() -> void:
	randomize()
	Globals.scene_ended.connect(self._on_end_scene)
	_start_audio()
	_start_game()


func _start_audio() -> void:
	music_players[0].play()
	_ambience_player.play()


func _process(_delta: float) -> void:
	if Input.is_action_pressed("quit"):
		get_tree().quit()


func _quit_game() -> void:
	get_tree().quit()


func _run_main_menu() -> void:
	var scene: MainMenu = main_menu.instantiate()
	self.current_scene = scene


func _start_game() -> void:
	GameState.reset()
	GameState.current_level_number = debug_only_start_level
	_run_level()


# Load current level
func _run_level() -> void:
	var scene: Level = level.instantiate()
	# Provies its settings to the level
	scene.init(levels[GameState.current_level_number])
	self.current_scene = scene


func _run_selected_level(level_i: int) -> void:
	GameState.reset()
	GameState.current_level_number = level_i
	_run_level()


func _run_level_selector() -> void:
	var scene: LevelSelector = level_selector.instantiate()
	scene.init(levels)
	self.current_scene = scene


func _on_end_of_level() -> void:
	if GameState.current_level_number >= levels.size() - 1 or GameState.family.is_player_dead():
		_load_stats_screen()
	else:
		_load_score_screen()


func _on_game_over() -> void:
	var scene: GameOver = game_over.instantiate()
	self.current_scene = scene


func _restart_level() -> void:
	_run_level()


func _load_score_screen() -> void:
	var scene: ScoreScreen = score_screen.instantiate()
	self.current_scene = scene


func _load_stats_screen() -> void:
	var scene: StatsScreen = stats_screen.instantiate()
	self.current_scene = scene


func _run_next_level() -> void:
	GameState.current_level_number += 1

	if GameState.current_level_number >= levels.size():
		# No more levels, end of the game
		_run_credits(false)
	else:
		# Load next level
		_run_level()


func _run_credits(can_go_back: bool) -> void:
	var scene: Credits = credits.instantiate()
	scene.set_back(can_go_back)
	self.current_scene = scene


func change_music_track(new_audio_player: AudioStreamPlayer) -> void:
	if current_audio_player != new_audio_player:
		for mp in music_players:
			mp.stop()
		new_audio_player.play()
		current_audio_player = new_audio_player


# State machine handling the state of the whole game
# Everytime a scene ends, it calls this function which will load the next
# step of the game
func _on_end_scene(status: Globals.EndSceneStatus, params: Dictionary = {}) -> void:
	match status:
		Globals.EndSceneStatus.MAIN_MENU_CLICK_START:
			_start_game()
		Globals.EndSceneStatus.MAIN_MENU_CLICK_SELECT_LEVEL:
			_run_level_selector()
		Globals.EndSceneStatus.MAIN_MENU_CLICK_CREDITS:
			_run_credits(true)
		Globals.EndSceneStatus.MAIN_MENU_CLICK_QUIT:
			_quit_game()
		Globals.EndSceneStatus.LEVEL_END:
			_on_end_of_level()
		Globals.EndSceneStatus.LEVEL_GAME_OVER:
			_on_game_over()
		Globals.EndSceneStatus.LEVEL_RESTART:
			_restart_level()
		Globals.EndSceneStatus.GAME_OVER_RESTART:
			_restart_level()
		Globals.EndSceneStatus.GAME_OVER_QUIT:
			_quit_game()
		Globals.EndSceneStatus.SCORE_SCREEN_NEXT:
			_run_next_level()
		Globals.EndSceneStatus.SCORE_SCREEN_RETRY:
			_restart_level()
		Globals.EndSceneStatus.SELECT_LEVEL_SELECTED:
			var level_i: int = params["level_i"]
			_run_selected_level(level_i)
		Globals.EndSceneStatus.SELECT_LEVEL_BACK:
			_run_main_menu()
		Globals.EndSceneStatus.CREDITS_BACK:
			_run_main_menu()
		Globals.EndSceneStatus.STATS_SCREEN_MENU:
			_run_main_menu()
		_:
			assert(false, "No handler for status " + str(status))
