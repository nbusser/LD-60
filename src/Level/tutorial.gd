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
	await (
		_pinny
		. say(
			[
				"Let me onboard you on your first day.",
				"Your position in Youpi is SEARCH ENGINEER. A very prestigious job! Lucky you!",
				"Your contract is only one week long, Monday to Saturday. If you perform well, we might propose to extend it."
			],
			Pinny.Mood.LAUGH
		)
	)
	await (
		_pinny
		. say(
			[
				"Your job is to manually reply to our CUSTOMERS' queries by EMAIL with appropriate RESULTS."
			],
			Pinny.Mood.NEUTRAL
		)
	)

	await (
		_pinny
		. instruct(
			[
				'First, check your email inbox by opening "Inlook"',
			],
			_is_running.bind("outbacks"),
			_desktop.program_opened
		)
	)

	# The request arrives once the mailbox is open
	_level_state.start_day()

	await get_tree().create_timer(1.5, false).timeout
	await _pinny.say(["How exciting! Your very first request!"], Pinny.Mood.LAUGH)
	await _pinny.say(
		[
			"It seems like someone is looking for a doctor.",
			"Find them a good link, and Youpi will pay you for it."
		]
	)
	await _pinny.say(["Wrong result, no money, pal! I'm not running a charity."], Pinny.Mood.LAUGH)

	await _pinny.instruct(
		['Open "Youpi?", our in-house database.'],
		_is_running.bind("youpi"),
		_desktop.program_opened
	)
	await get_tree().create_timer(1.5, false).timeout

	await _pinny.instruct(
		["Everything is sorted by category. Click Health, then Doctors."],
		_is_browsing_doctors,
		GameState.category_browsed
	)

	await _pinny.instruct(
		[
			"Now, the tedious work starts: copy that LINK, then click Send. Better links pay more. You can do it, buddy! I believe in you!",
		],
		func(): return _level_state.resolved_requests > 0,
		_level_state.request_resolved
	)

	if GameState.money > 0:
		await _pinny.say(["Well done! See? Easy money."], Pinny.Mood.LAUGH)
	else:
		await _pinny.say(
			["If you chose a better link, you would have earned some money."], Pinny.Mood.LAUGH
		)

	await (
		_pinny
		. say(
			[
				"This customer was exceptionally patient, but most customers will demand that you answer within a limited time. So no time to slack off, pal.",
				"At Youpi, we value individual performance. With your hard-earned money, you can buy some tools from us that we reserve for our most cherished employees.",
			],
			Pinny.Mood.NEUTRAL
		)
	)

	await (
		_pinny
		. instruct(
			[
				"Open the Shop application, pal.",
			],
			_is_running.bind("shop"),
			_desktop.program_opened
		)
	)
	await get_tree().create_timer(1.5, false).timeout

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
				"That's all, pal! Have a nice first day.",
			],
			Pinny.Mood.LAUGH
		)
	)
	await _pinny.leave()


func _is_running(program_id: String) -> bool:
	return _desktop.is_program_running(program_id)


func _on_category_browsed(path: PackedStringArray) -> void:
	_browsed_path = path


# Accept any route that ends on the Doctors category. The directory emits the
# full path now, but this also keeps the tutorial working if the player reaches
# Doctors through a shortcut (for example the link shown on the Health tile).
func _is_browsing_doctors() -> bool:
	return not _browsed_path.is_empty() and _browsed_path[-1] == DOCTORS_PATH[-1]
