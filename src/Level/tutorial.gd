class_name Tutorial
extends Node

const DOCTORS_PATH: PackedStringArray = ["Health", "Doctors"]

var _desktop: Desktop
var _pinny: Pinny
var _level_state: LevelState
var _browsed_path := PackedStringArray()


func _init(desktop: Desktop, level_state: LevelState) -> void:
	name = "Tutorial"
	_desktop = desktop
	_pinny = desktop.pinny
	_level_state = level_state

	GameState.category_browsed.connect(_on_category_browsed)


func run() -> void:
	await _pinny.appear()
	await _pinny.say(
		[
			"Let me onboard you for this first day.",
			"Your position in Youpi is SEARCH ENGINEER. A very prestigious job! Lucky you!"
		],
		Pinny.Mood.LAUGH
	)
	await _pinny.say(
		["Your job is to manually reply to our CUSTOMERS queries' EMAIL with appropriate RESULTS."],
		Pinny.Mood.NEUTRAL
	)

	await _instruct(
		[
			'First, check your email inbox by opening "Outbacks"',
		],
		_is_running.bind("outbacks"),
		_desktop.program_opened
	)

	# The request arrives once the mailbox is open
	_level_state.start_day()

	await get_tree().create_timer(1.5).timeout
	await _pinny.say(["How exciting! You very first request!"], Pinny.Mood.LAUGH)
	await _pinny.say(
		[
			"It seems like someone is looking for a doctor.",
			"Find them a good link, and Youpi will pay you for it."
		]
	)
	await _pinny.say(
		["Wrong result, no money, pal! We are not commies; we are not doing charity"],
		Pinny.Mood.LAUGH
	)

	await _instruct(
		['Open "Youpi?", our in-house database.'],
		_is_running.bind("youpi"),
		_desktop.program_opened
	)
	await get_tree().create_timer(1.5).timeout

	await _instruct(
		["Everything is sorted by category. Click Health, then Doctors."],
		func(): return _browsed_path == DOCTORS_PATH,
		GameState.category_browsed
	)

	await _instruct(
		[
			"Now, the tedious work starts: copy the LINK manually. Then click Send. Better links pay more. You can do it pal! I believe in you!",
		],
		func(): return _level_state.resolved_requests > 0,
		_level_state.request_resolved
	)

	await _pinny.say(["Well done! See? Easy money."], Pinny.Mood.LAUGH)
	await (
		_pinny
		. say(
			[
				"This customer was exceptionally patient, but most customer will demand you to answer within a limited time, so, no time to slack off pal.",
				"In Youpi, we value individual performances. With you hardly-earned money, you can buy some tools from us that we reserve for our best employees.",
			],
			Pinny.Mood.NEUTRAL
		)
	)

	await _instruct(
		["Open the Shop application pal."],
		# I don't know why but the shop is not properly detected
		# TODO: debug it
		# _is_running.bind("shop"),
		# _desktop.program_opened
		func(): return true,
		get_tree().create_timer(0.2).timeout
	)
	await get_tree().create_timer(1.5).timeout

	await (
		_pinny
		. say(
			[
				"Typing links by hand is slow. When you can afford it, buy Copy & Paste.",
			],
			Pinny.Mood.LAUGH
		)
	)
	await (
		_pinny
		. say(
			[
				"That's all pal! Have a nice first day.",
			],
			Pinny.Mood.LAUGH
		)
	)
	await _pinny.leave()


# Pinny explains what to do and keeps the instruction on screen until it is done
func _instruct(pages: Array[String], is_done: Callable, changed: Signal) -> void:
	_pinny.say(pages, Pinny.Mood.NEUTRAL, true)
	while not is_done.call():
		await changed


func _is_running(program_id: String) -> bool:
	return _desktop.is_program_running(program_id)


func _on_category_browsed(path: PackedStringArray) -> void:
	_browsed_path = path
