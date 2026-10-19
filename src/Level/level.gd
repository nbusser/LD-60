class_name Level

extends Node

# Each level runs its own scenario: see _run_level_<n>()

# Emitted by _finish_day(), awaited by _play_day()
signal day_finished

const DAY_START_HOUR := 8
const DAY_END_HOUR := 20

const SETUP: Program = preload("res://assets/data/program/setup.tres")
const FAMILY_PHOTOS: Program = preload("res://assets/data/program/family_viewer.tres")
const FAMILY_PHOTOS_ID := "family_photos"

var level_state: LevelState

var _desktop: Desktop
var _pinny: Pinny
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

	_update_clock()

	$UI/Fadein.fade()
	match GameState.current_level_number:
		0:
			await _run_level_0()
		1:
			await _run_level_1(self.level_state.level_data)
		2:
			await _run_level_2(self.level_state.level_data)
		3:
			await _run_level_3(self.level_state.level_data)
		4:
			await _run_level_4(self.level_state.level_data)
		_:
			assert(false, "No scenario for level %d" % GameState.current_level_number)

	await _turn_off_screen()
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
	await _play_day()

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


func _run_level_1(level_data: LevelData) -> void:
	await _pinny.appear()
	await (
		_pinny
		. say(
			[
				"Good morning pal! Great work yesterday.",
				"I left you a little gift on your desktop.",
			],
			Pinny.Mood.LAUGH
		)
	)

	# The gift shows up once Pinny mentions it
	_desktop.add_program(FAMILY_PHOTOS)
	await _pinny.instruct(
		["Go on pal, open it!"],
		_desktop.is_program_running.bind(FAMILY_PHOTOS_ID),
		_desktop.program_opened
	)

	# Let the player look at the photos before coming back
	await get_tree().create_timer(8.0).timeout

	await (
		_pinny
		. say(
			[
				"Lovely family, isn't it? I heard a lot about you from them.",
				"Did you hear from them since they left for vacations two days ago? Don't worry, they are safe. I keep them safe... for now.",
				(
					"Let's cut to the chase, the fee for your Dad is $%d. Pay by the end of your work day. If you don't, you will never see him again, except in photo."
					% [level_data.ransom]
				),
				"Enjoy your day, and don't overthink it."
			],
			Pinny.Mood.ANGRY
		)
	)
	await _pinny.leave()

	await _play_day()

	# TODO quand la journee se termine: ouvrir une popup qui dit que la journee se finit.
	# Quand on la ferme ca ferme toutes les fenetres, et on empeche l'user d'ouvrir lui meme d'autres fenetres puis on commence la cutscene de fin de niveau

	await _pinny.appear()
	await _pinny.say(
		[
			"Well, well, well, how was your day, pal?",
			"Oh dear, you have a terrible face. Please don't burn yourself out."
		],
		Pinny.Mood.LAUGH
	)
	await (
		_pinny
		. say(
			[
				"Do you have the money I kindly asked to you?",
			],
			Pinny.Mood.NEUTRAL
		)
	)

	var could_pay: bool = GameState.money >= level_data.ransom
	GameState.money = max(0, GameState.money - level_data.ransom)

	await get_tree().create_timer(1.5).timeout

	if could_pay:
		await _pinny.say(
			[
				"Good! You learned fast. You Dad is safe for now.",
				"See you tomorrow, don't be late.",
				"Sleep well pal."
			],
			Pinny.Mood.NEUTRAL
		)
	else:
		await (
			_pinny
			. say(
				[
					"Oh... Too bad...",
					"Don't worry, I know this is your first day. You know I have a heart. Let me bring you back some chocolate. You deserved it.",
				],
				Pinny.Mood.NEUTRAL
			)
		)
		await _pinny.leave()

		await get_tree().create_timer(1.3).timeout
		await Sfx.play_kill()
		await get_tree().create_timer(0.5).timeout
		await Sfx.play_photo()
		await get_tree().create_timer(0.5).timeout

		await _pinny.appear()
		await (
			_pinny
			. say(
				[
					"Sorry, I changed my mind. No chocolate for you. But I have this instead.",
				],
				Pinny.Mood.NEUTRAL
			)
		)

		await get_tree().create_timer(0.5).timeout

		GameState.kill(level_data.hostage)
		_desktop.show_image(
			level_data.hostage.terminated_file_name(), level_data.hostage.portrait_terminated
		)

		await get_tree().create_timer(2.2).timeout

		await (
			_pinny
			. say(
				[
					"Dad is gone... How sad... He would be alive if his son was not SLACKING OFF. See you tomorrow for the next round.",
				],
				Pinny.Mood.ANGRY
			)
		)

	await _pinny.leave()


func _run_level_2(level_data: LevelData) -> void:
	_desktop.add_program(FAMILY_PHOTOS)
	await (
		_pinny
		. visit(
			[
				"Today I want $%d for Mommy." % [level_data.ransom],
				"Don't get sentimental. It's just business.",
			],
			Pinny.Mood.ANGRY
		)
	)

	await _play_day()

	# TODO: write ransom dialog


func _run_level_3(level_data: LevelData) -> void:
	_desktop.add_program(FAMILY_PHOTOS)
	await (
		_pinny
		. visit(
			[
				"Halfway through the week. You look tired.",
				"$%d for your Son. Same rules." % [level_data.ransom],
				"The directory remembers everything. So do I.",
			],
			Pinny.Mood.ANGRY
		)
	)

	await _play_day()

	# TODO: write ransom dialog


func _run_level_4(level_data: LevelData) -> void:
	_desktop.add_program(FAMILY_PHOTOS)
	await (
		_pinny
		. visit(
			[
				"One more photo after this one.",
				"$%d for your sweet Daughter. Then we talk about you." % [level_data.ransom],
				"You can spend your money in the shop. Just not on them.",
			],
			Pinny.Mood.ANGRY
		)
	)

	await _play_day()

	# TODO: write ransom dialog


# Helpers


# Sends the requests until they are all answered or timed out
func _play_day() -> void:
	_running = true
	level_state.is_clock_running = true
	level_state.start_day()
	await day_finished


# Polled rather than signaled: requests may all be resolved before _play_day(),
# and day_finished must not be emitted before _play_day() awaits it
func _process(_delta: float) -> void:
	if not _running:
		return

	_update_clock()
	if level_state.resolved_requests >= level_state.total_requests:
		_finish_day()


func _finish_day() -> void:
	if level_state.is_day_over:
		return

	level_state.is_day_over = true
	_running = false
	level_state.is_clock_running = false
	_update_clock()
	day_finished.emit()


# Old CRT turning off: the screen collapses into a line, then into a dot
func _turn_off_screen() -> void:
	var backdrop := CanvasLayer.new()
	backdrop.layer = -1
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(black)
	add_child(backdrop)

	_desktop.pivot_offset = _desktop.size / 2.0
	var tween := create_tween()
	tween.tween_property(_desktop, "modulate", Color(4.0, 4.0, 4.0), 0.12)
	tween.parallel().tween_property(_desktop, "scale:y", 0.004, 0.15)
	tween.tween_property(_desktop, "scale:x", 0.0, 0.2)
	Sfx.play_shut_down()
	await tween.finished
	await get_tree().create_timer(0.5).timeout


func _update_clock() -> void:
	if _desktop == null:
		return

	# The clock follows the resolved requests, the day ends with the last one
	var total := level_state.total_requests
	var progress := float(level_state.resolved_requests) / total if total > 0 else 1.0
	var day_minutes := (DAY_END_HOUR - DAY_START_HOUR) * 60
	var total_minutes := DAY_START_HOUR * 60 + int(round(progress * day_minutes))
	total_minutes = clampi(total_minutes, DAY_START_HOUR * 60, DAY_END_HOUR * 60)
	_desktop.set_clock(total_minutes / 60, total_minutes % 60)
