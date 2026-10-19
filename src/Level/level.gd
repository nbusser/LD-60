class_name Level

extends Node

const DAY_START_HOUR := 8
const DAY_END_HOUR := 20

var level_state: LevelState

var _desktop: Desktop
var _time_left := 0.0
var _running := false

@onready var _desktop_scene := preload("res://src/BrowserGame/Desktop/desktop.tscn")


func _ready():
	assert(level_state, "init must be called before creating Level scene")

	var map: Control
	match self.level_state.level_data.type:
		LevelData.LevelType.BROWSER:
			map = _desktop_scene.instantiate()
		_:
			assert(false, "Invalid level type")
	add_child(map)
	_desktop = map as Desktop

	var tutorial: Tutorial = null
	if level_state.level_data.is_tutorial:
		tutorial = Tutorial.new(_desktop, level_state)
		add_child(tutorial)
	else:
		GameState.start_day(level_state.level_data.day_index)
	_time_left = float(level_state.level_data.timer_duration)
	_update_clock()

	await _run_setup()

	if tutorial != null:
		await tutorial.run()
		await _end_tutorial()
		return

	await _threaten()

	level_state.all_requests_resolved.connect(_on_all_requests_resolved)
	_running = true
	level_state.start_day()

	$UI/Fadein.fade()


func init(level_data_p: LevelData):
	level_data_p.load_requests()
	level_state = LevelState.new(level_data_p)
	GameState.level_state = level_state


func _process(delta: float) -> void:
	if not _running:
		return

	_time_left = maxf(_time_left - delta, 0.0)
	_update_clock()
	if _time_left <= 0.0:
		_end_day()


func _run_setup() -> void:
	if GameState.needs_setup():
		GameState.setup_install_started.connect(_on_setup_install_started, CONNECT_ONE_SHOT)
	while GameState.needs_setup():
		await GameState.setup_completed
	# wait for Pinny to finish the setup visit
	while _desktop.pinny.is_present:
		await get_tree().process_frame


func _end_tutorial() -> void:
	level_state.is_day_over = true
	await $UI/Fadeout.fade()
	Globals.end_scene(Globals.EndSceneStatus.LEVEL_END)


func _on_setup_install_started() -> void:
	await (
		_desktop
		. pinny
		. visit(
			[
				"Howdy, I'm Pinny. I am your nice desktop assistant.",
				"Welcome to Youpi! Sit back and relax, I'm installing everything you need.",
				"I'm gonna grab a cofee. I will come back for your proper onboarding.",
			],
			Pinny.Mood.LAUGH
		)
	)


func _threaten() -> void:
	await _desktop.pinny.visit(_threat_lines(), Pinny.Mood.ANGRY)


func _threat_lines() -> Array[String]:
	var fee := GameState.protection_fee
	if GameState.is_player_threatened():
		return [
			"Last day. No more family photos.",
			"$%d for your own life." % fee,
			"You paid for them. Now pay for yourself.",
		]

	var relation := GameState.threatened_member().relation
	match GameState.day_index:
		0:
			return [
				"Oh, one more thing. I know you better than you think. I heard a lot about you from your nice little family.",
				"Did you hear from them since they left for vacations two days ago? Don't worry, they are safe. I keep them safe... for now.",
				(
					"Let's cut to the chase, the fee for %s is $%d. Pay by 20:00. If you don't, you will never see him again, except in photo."
					% [relation, fee]
				),
				"Enjoy your day, and don't overthink it."
			]
		1:
			return [
				"You paid last time. I noticed.",
				"Today I want $%d for %s." % [fee, relation],
				"Don't get sentimental. It's just business.",
			]
		2:
			return [
				"Halfway through the week. You look tired.",
				"$%d for %s. Same rules." % [fee, relation],
				"The directory remembers everything. So do I.",
			]
		3:
			return [
				"One more photo after this one.",
				"$%d for %s. Then we talk about you." % [fee, relation],
				"You can spend your money in the shop. Just not on them.",
			]
	return []


func _on_all_requests_resolved() -> void:
	_end_day()


func _end_day() -> void:
	if level_state.is_day_over:
		return

	level_state.is_day_over = true
	_running = false
	_update_clock()

	var success := GameState.resolve_protection()
	await _desktop.pinny.visit(
		_collection_lines(success), Pinny.Mood.NEUTRAL if success else Pinny.Mood.LAUGH
	)
	Globals.end_scene(Globals.EndSceneStatus.LEVEL_END)


func _collection_lines(success: bool) -> Array[String]:
	var fee := GameState.protection_fee
	var target := GameState.threatened_name()
	var player := GameState.is_player_threatened()

	if success:
		if player:
			return ["You paid. I will see you tomorrow.", "$%d, right on time." % fee]
		return ["$%d. %s lives." % [fee, target], "Pleasure doing business."]

	if player:
		return ["You are short. You know what happens now."]
	return ["You are short. I take everything.", "%s is gone." % target]


func _update_clock() -> void:
	if _desktop == null:
		return

	var duration := float(level_state.level_data.timer_duration)
	var elapsed := duration - _time_left
	var day_minutes := (DAY_END_HOUR - DAY_START_HOUR) * 60
	var total_minutes := DAY_START_HOUR * 60
	if duration > 0.0:
		total_minutes += int(round(elapsed / duration * day_minutes))
	total_minutes = clampi(total_minutes, DAY_START_HOUR * 60, DAY_END_HOUR * 60)
	_desktop.set_clock(total_minutes / 60, total_minutes % 60)
