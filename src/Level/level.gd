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

	GameState.start_day(GameState.current_level_number)
	_time_left = float(level_state.level_data.timer_duration)
	_update_clock()
	if GameState.needs_setup():
		GameState.setup_install_started.connect(_on_setup_install_started, CONNECT_ONE_SHOT)
	while GameState.needs_setup():
		await GameState.setup_completed
	# wait for Pinny to finish the setup visit
	while _desktop.pinny.is_present:
		await get_tree().process_frame
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


func _on_setup_install_started() -> void:
	await (
		_desktop
		. pinny
		. visit(
			[
				"Howdy, I'm Pinny. I am your nice desktop assistant.",
				"Sit back and relax, I'm installing everything you need.",
				"You'll see, I thought of everything.",
			],
			Pinny.Mood.LAUGH
		)
	)


func _threaten() -> void:
	await _desktop.pinny.visit(_threat_lines(), Pinny.Mood.ANGRY)


func _threat_lines() -> Array[String]:
	var fee := GameState.protection_fee
	var member := GameState.threatened_member()
	var relation := member.relation if member != null else "your family"
	var name := member.display_name if member != null else "them"

	match GameState.day_index:
		0:
			return [
				"Oh actually, I know you already but you don't know me. I heard a lot about you from your nice little family.",
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
		_:
			return [
				"Last day. No more family photos.",
				"$%d for your own life." % fee,
				"You paid for %s. Now pay for yourself." % name,
			]


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
	var fee := GameState.last_day_fee
	var member := GameState.family_member(GameState.last_day_target_id)
	var target := member.display_name if member != null else "you"

	if success:
		if GameState.last_day_target_id == GameState.PLAYER_ID:
			return ["You paid. I will see you tomorrow.", "$%d, right on time." % fee]
		return ["$%d. %s lives." % [fee, target], "Pleasure doing business."]

	if GameState.last_day_target_id == GameState.PLAYER_ID:
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
