class_name Level

extends Node

# Each level runs its own scenario: see _run_level_<n>()

# Emitted by _finish_day(), awaited by _play_day()
signal day_finished

const DAY_START_HOUR := 8
const DAY_END_HOUR := 20

const SETUP: Program = preload("res://assets/data/program/setup.tres")
const FAMILY_PHOTOS: Program = preload("res://family_viewer.tres")
const FAMILY_PHOTOS_ID := "family_photos"

var level_state: LevelState

var _desktop: Desktop
var _pinny: Pinny
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
	_pinny = _desktop.pinny

	_time_left = float(level_state.level_data.timer_duration)
	_update_clock()

	match GameState.current_level_number:
		0:
			await _run_level_0()
		1:
			await _run_level_1()
		2:
			await _run_level_2()
		3:
			await _run_level_3()
		4:
			await _run_level_4()
		5:
			await _run_level_5()
		_:
			assert(false, "No scenario for level %d" % GameState.current_level_number)

	Globals.end_scene(Globals.EndSceneStatus.LEVEL_END)


func init(level_data_p: LevelData):
	level_data_p.load_requests()
	level_state = LevelState.new(level_data_p)
	GameState.level_state = level_state


# MARK: Scenarios


func _run_level_0() -> void:
	# created before the setup to track what the player does meanwhile
	var tutorial := Tutorial.new(_desktop, level_state)
	add_child(tutorial)

	if not Globals.skip_setup:
		await _run_setup()

	# The tutorial starts the day once the mailbox is open, the clock runs after it
	await tutorial.run()
	await _play_day(false)

	await (_pinny.visit(["Good job on your first day pal! Get some rest."], Pinny.Mood.LAUGH))


# Only the Setup icon is on the desktop, each install step reveals a program
func _run_setup() -> void:
	_desktop.hide_icons()
	_desktop.add_program(SETUP)
	GameState.setup_install_started.connect(_on_setup_install_started, CONNECT_ONE_SHOT)
	GameState.setup_step_installed.connect(_desktop.reveal_next_icon)

	await GameState.setup_completed

	GameState.setup_step_installed.disconnect(_desktop.reveal_next_icon)
	_desktop.remove_program(SETUP)
	_desktop.show_icons()


func _on_setup_install_started() -> void:
	await _pinny.appear()
	await (
		_pinny
		. say(
			[
				"Howdy, I'm Pinny. I am your nice desktop assistant.",
				"Welcome to Youpi! Sit back and relax, I'm installing everything you need.",
			],
			Pinny.Mood.LAUGH
		)
	)


func _run_level_1() -> void:
	GameState.start_day(0)
	var fee := GameState.protection_fee
	var relation := GameState.threatened_member().relation

	_desktop.add_program(FAMILY_PHOTOS)
	await _pinny.appear()
	await (
		_pinny
		. say(
			[
				"Good morning pal! Great work yesterday.",
				"I left you a little gift on your desktop. Go on, open it!",
			],
			Pinny.Mood.LAUGH
		)
	)

	# Let the player look at the photos before coming back
	var deadline := Time.get_ticks_msec() + 15000
	while not _desktop.is_program_running(FAMILY_PHOTOS_ID) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	await get_tree().create_timer(4.0).timeout

	await (
		_pinny
		. say(
			[
				"Lovely family, isn't it? I heard a lot about you from them.",
				"Did you hear from them since they left for vacations two days ago? Don't worry, they are safe. I keep them safe... for now.",
				(
					"Let's cut to the chase, the fee for %s is $%d. Pay by 20:00. If you don't, you will never see him again, except in photo."
					% [relation, fee]
				),
				"Enjoy your day, and don't overthink it."
			],
			Pinny.Mood.ANGRY
		)
	)
	await _pinny.leave()

	await _play_day()
	await _collect_fee()


func _run_level_2() -> void:
	GameState.start_day(1)
	var fee := GameState.protection_fee
	var relation := GameState.threatened_member().relation

	_desktop.add_program(FAMILY_PHOTOS)
	await (
		_pinny
		. visit(
			[
				"You paid last time. I noticed.",
				"Today I want $%d for %s." % [fee, relation],
				"Don't get sentimental. It's just business.",
			],
			Pinny.Mood.ANGRY
		)
	)

	await _play_day()
	await _collect_fee()


func _run_level_3() -> void:
	GameState.start_day(2)
	var fee := GameState.protection_fee
	var relation := GameState.threatened_member().relation

	_desktop.add_program(FAMILY_PHOTOS)
	await (
		_pinny
		. visit(
			[
				"Halfway through the week. You look tired.",
				"$%d for %s. Same rules." % [fee, relation],
				"The directory remembers everything. So do I.",
			],
			Pinny.Mood.ANGRY
		)
	)

	await _play_day()
	await _collect_fee()


func _run_level_4() -> void:
	GameState.start_day(3)
	var fee := GameState.protection_fee
	var relation := GameState.threatened_member().relation

	_desktop.add_program(FAMILY_PHOTOS)
	await (
		_pinny
		. visit(
			[
				"One more photo after this one.",
				"$%d for %s. Then we talk about you." % [fee, relation],
				"You can spend your money in the shop. Just not on them.",
			],
			Pinny.Mood.ANGRY
		)
	)

	await _play_day()
	await _collect_fee()


# Day 6: the player is the target
func _run_level_5() -> void:
	GameState.start_day(4)
	var fee := GameState.protection_fee

	_desktop.add_program(FAMILY_PHOTOS)
	await (
		_pinny
		. visit(
			[
				"Last day. No more family photos.",
				"$%d for your own life." % fee,
				"You paid for them. Now pay for yourself.",
			],
			Pinny.Mood.ANGRY
		)
	)

	await _play_day()
	await _collect_fee()


# Helpers


# Runs the clock and sends the requests until the end of the day
func _play_day(fade_in := true) -> void:
	level_state.all_requests_resolved.connect(_finish_day)
	_running = true
	level_state.is_clock_running = true
	level_state.start_day()
	if fade_in:
		$UI/Fadein.fade()
	await day_finished


func _process(delta: float) -> void:
	if not _running:
		return

	_time_left = maxf(_time_left - delta, 0.0)
	_update_clock()
	if _time_left <= 0.0:
		_finish_day()


func _finish_day() -> void:
	if level_state.is_day_over:
		return

	level_state.is_day_over = true
	_running = false
	level_state.is_clock_running = false
	_update_clock()
	day_finished.emit()


# Pinny takes the fee, or everything and the threatened member
func _collect_fee() -> void:
	var fee := GameState.protection_fee
	var target := GameState.threatened_name()
	var player := GameState.is_player_threatened()

	var lines: Array[String]
	if GameState.resolve_protection():
		if player:
			lines = ["You paid. I will see you tomorrow.", "$%d, right on time." % fee]
		else:
			lines = ["$%d. %s lives." % [fee, target], "Pleasure doing business."]
		await _pinny.visit(lines, Pinny.Mood.NEUTRAL)
	else:
		if player:
			lines = ["You are short. You know what happens now."]
		else:
			lines = ["You are short. I take everything.", "%s is gone." % target]
		await _pinny.visit(lines, Pinny.Mood.LAUGH)


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
