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
const YOUPI_ICON := preload("res://assets/sprites/icons/icon-32.png")
const YOUPI_ICON_16 := preload("res://assets/sprites/icons/icon-16.png")

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

	if GameState.current_level_number > 1:
		_desktop.add_program(FAMILY_PHOTOS)

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
		5:
			await _run_level_5(self.level_state.level_data)
		_:
			assert(false, "No scenario for level %d" % GameState.current_level_number)

	await _turn_off_screen()

	get_tree().create_timer(0.2, false)
	await $UI/Fadeout.fade()

	Globals.end_scene(Globals.EndSceneStatus.LEVEL_END)


func _exit_tree() -> void:
	# The music bus is shared with the next scenes
	_set_music_muted(false)


func init(level_data_p: LevelData):
	level_data_p.load_requests()
	level_state = LevelState.new(level_data_p)
	GameState.level_state = level_state


# MARK: Scenarios

# MARK: Level 0


func _run_level_0() -> void:
	# created before the setup to track what the player does meanwhile
	var tutorial := Tutorial.new(_desktop, level_state)
	add_child(tutorial)

	if not Globals.skip_setup:
		await _run_setup()

	# The tutorial starts the day once the mailbox is open, the clock runs after it
	await tutorial.run()
	await _play_day()

	await (_pinny.visit(["Good job on your first day, pal! Get some rest."], Pinny.Mood.LAUGH))


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
				"Howdy friend! I am Pinny, your friendly desktop assistant.",
				"Welcome to Youpi! Sit back and relax. I'm installing everything you need.",
			],
			Pinny.Mood.LAUGH
		)
	)


# MARK: Level 1


func _run_level_1(level_data: LevelData) -> void:
	await _pinny.appear()
	await (
		_pinny
		. say(
			[
				"Good morning, pal! Great work yesterday.",
				"I left you a little gift on your desktop.",
			],
			Pinny.Mood.LAUGH
		)
	)

	# The gift shows up once Pinny mentions it
	_desktop.add_program(FAMILY_PHOTOS)
	await _pinny.instruct(
		["Go on friend, open it!"],
		_desktop.is_program_running.bind(FAMILY_PHOTOS_ID),
		_desktop.program_opened
	)

	# Let the player look at the photos before coming back
	await get_tree().create_timer(8.0, false).timeout

	_set_music_muted(true)
	await (
		_pinny
		. say(
			[
				"Lovely family, isn't it? I heard a lot about you from them.",
				"Have you heard from them since they left for vacation two days ago? Don't worry, they are safe.",
				"...",
				"...as long as you pay, that is. I need money to buy cigarettes, you know...",
				"...",
				"I keep them comfortably in my basement. Your kids cried a lot, but at some point they realized it was pointless. Your parents, however, are slowly starting to panic...",
				"Let's cut to the chase. The fee for your Dad is $%d." % [level_data.ransom],
				"...",
				"Pay by the end of your work day."
			],
			Pinny.Mood.ANGRY
		)
	)
	await (_pinny.say(["Enjoy your day, and don't overthink it."], Pinny.Mood.LAUGH))

	await _pinny.leave()
	_set_music_muted(false)

	await _play_day()

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
				"Do you have the money I kindly asked you for?",
			],
			Pinny.Mood.NEUTRAL
		)
	)

	await (_collect_ransom(
		level_data,
		GameState.DAD,
		[
			# paid
			"Good! You learned fast. Your Dad is safe for now.",
			"See you tomorrow. Don't be late.",
			"Sleep well, friend."
		],
		[
			# unpaid
			"Oh... Too bad...",
			"Don't worry, I know this is your first day. You know I have a heart. Let me bring you back some chocolate. You deserve it.",
		],
		[
			# reveal
			"Sorry, I changed my mind. No chocolate for you. But I have this instead.",
		],
		[
			# aftermath
			"Dad is gone... How sad... He would be alive if his son had not been SLACKING OFF. See you tomorrow for the next round.",
		]
	))


# MARK: Level 2


func _run_level_2(level_data: LevelData) -> void:
	await _pinny.appear()
	await (
		_pinny
		. say(
			[
				"Good morning to you, my favorite employee. Did you sleep well?",
				(
					"Did you dream of your dad? Is he in hell? In heaven?"
					if not GameState.is_alive(GameState.DAD)
					else "Your dad slept terribly too."
				),
			],
			Pinny.Mood.LAUGH
		)
	)
	await (_pinny.say(
		[
			(
				"Today I want $%d for Mommy. Don't get sentimental. It's just business."
				% [level_data.ransom]
			),
			"Have a wonderful day."
		],
		Pinny.Mood.ANGRY
	))
	await _pinny.leave()

	await _play_day()

	await _pinny.appear()
	await _pinny.say(["TIME'S UP! MONEY TIME!", "Do you have the ransom, son?"], Pinny.Mood.NEUTRAL)

	await (_collect_ransom(
		level_data,
		GameState.MOM,
		[
			# paid
			"Such a hard worker...",
			(
				"Daddy would have been proud!"
				if not GameState.is_alive(GameState.DAD)
				else "Saving both your parents... Look at you, busy bee!"
			),
			"Mommy is safe. Don't skip the alarm tomorrow."
		],
		[
			# unpaid
			(
				"AGAIN?"
				if not GameState.is_alive(GameState.DAD)
				else "At least you won't be completely orphaned."
			),
			"What kind of son are you... letting your Mom die!",
		],
		[
			# reveal
			"Here she is...",
		],
		[
			# aftermath
			"Stay tuned. Tomorrow, things are going to get serious...",
		]
	))


# MARK: Level 3


func _run_level_3(level_data: LevelData) -> void:
	await _pinny.appear()
	await (
		_pinny
		. say(
			[
				"Halfway through the week. You look tired.",
				"$%d for your son. Same rules." % [level_data.ransom],
				"The directory remembers everything. So do I.",
			],
			Pinny.Mood.ANGRY
		)
	)
	await (
		_pinny
		. say(
			[
				"Do you mind if I stay here? I just want to make sure that you are handling everything well.",
				"Please just pretend I'm not here."
			],
			Pinny.Mood.NEUTRAL
		)
	)

	await _play_day()

	await (
		_pinny
		. say(
			[
				"Ding ding! Day's over, pal. Let's see that wallet. I hope for your sake it is heavy enough."
			],
			Pinny.Mood.NEUTRAL
		)
	)

	await _collect_ransom(
		level_data,
		GameState.SON,
		# paid
		(
			(func() -> Array[String]:
				var res: Array[String] = [
					"It seems like you did not miss a single penny.",
					"Your lineage is partly saved."
				]
				if not GameState.is_alive(GameState.DAD) and not GameState.is_alive(GameState.MOM):
					res.append_array(
						[
							"Finally you started to understand your job...",
							"It took you long enough to deprive your son of his grandparents..."
						]
					)
				res.append_array(["Stay focused."])
				return res)
			. call()
		),
		# unpaid
		(
			(func() -> Array[String]:
				if not GameState.is_alive(GameState.DAD) and not GameState.is_alive(GameState.MOM):
					return [
						"I'm so sorry, but you are really bad at this job...",
						"You could not keep a single one yet."
					]
				if GameState.is_alive(GameState.DAD) and GameState.is_alive(GameState.MOM):
					return [
						"Saving your parents... to deprive them of their grandson... Aren't you ashamed?"
					]
				return ["I'm sure you can do better..."])
			. call()
		),
		[
			# reveal
			"I hate doing that.",
		],
		[
			# aftermath
			"Only your daughter's fate is yet to come. Think about her tonight.",
		]
	)


# MARK: Level 4


func _run_level_4(level_data: LevelData) -> void:
	await (
		_pinny
		. visit(
			[
				"'mornin!",
				"Sorry, I feel groggy. I haven't had my coffee yet.",
				(
					"$%d for your sweet daughter. Then I'm done taking care of your family."
					% [level_data.ransom]
				),
				"You can spend your money in the shop. Just not on them.",
			],
			Pinny.Mood.ANGRY
		)
	)

	await _play_day()

	await _pinny.appear()
	await _pinny.say(["Last family member, last payment. Show me."], Pinny.Mood.NEUTRAL)

	await (_collect_ransom(
		level_data,
		GameState.DAUGHTER,
		# paid
		(
			(func() -> Array[String]:
				var res: Array[String] = []
				if GameState.total_death() == 0:
					(
						res
						. append_array(
							[
								"I have to admit I am impressed.",
								"In more than two years of my career, I have rarely seen that.",
								"Your whole family is safe. I should feel it is unfair, but I am happy for you, pal.",
							]
						)
					)
				if GameState.total_death() == 3:
					res.append_array(
						[
							"Everyone's dead... But your daughter...",
							"I don't know if she should consider herself lucky or not..."
						]
					)
				if not GameState.is_alive(GameState.SON):
					res.append_array(["So sad that she is an only child now..."])
				res.append_array(
					["Anyway! Tomorrow is your last day. Make sure to come for your offboarding."]
				)
				return res)
			. call()
		),
		# unpaid
		(
			(func() -> Array[String]:
				var res: Array[String] = []
				if GameState.total_death() == 0:
					res.append_array(
						[
							"Oh, pal, you were so close!",
							"But I'm sorry, you play the game, you pay the price..."
						]
					)
				elif GameState.total_death() == 3:
					res.append_array(
						[
							"Everyone's dead... But your daughter...",
							"I don't know if she should consider herself lucky or not..."
						]
					)
				elif not GameState.is_alive(GameState.SON):
					res.append_array(["No more lineage! It's official."])
				else:
					res.append_array(
						["I'm really sorry for your daughter. She did not deserve that."]
					)
				return res)
			. call()
		),
		[
			# reveal
			"The last picture. Keep it somewhere safe.",
		],
		[
			# aftermath
			"Anyway! Tomorrow is your last day. Make sure to come for your offboarding.",
		]
	))


# MARK: Level 5


func _run_level_5(level_data: LevelData) -> void:
	await (_pinny.visit(
		(
			(func() -> Array[String]:
				var res: Array[String] = ["It's already your last day, pal. Aren't you sad?"]
				if GameState.total_death() == 4:
					(
						res
						. append_array(
							[
								"My sincere condolences for your family.",
								"You must hate me, but I assure you that my job is not easy.",
								"I feel remorse sometimes, and I have the role of the bad guy in this story.",
								"But someone has to do it right?"
							]
						)
					)
				elif GameState.total_death() == 0:
					(
						res
						. append_array(
							[
								"I'm glad that you will finally meet your whole family again. What an adventure!"
							]
						)
					)
				else:
					(
						res
						. append_array(
							[
								"At least you will meet your family again... I mean, what remains of it..."
							]
						)
					)
				return res)
			. call()
		),
		Pinny.Mood.NEUTRAL
	))

	await get_tree().create_timer(1.0, false).timeout

	await (_pinny.visit(
		[
			"Oh! I almost forgot!",
			"Don't miss your offboarding after your workday!",
			(
				"I hope you can collect at least $%d. It would be great for your last day"
				% level_data.ransom
			)
		],
		Pinny.Mood.LAUGH
	))

	await _play_day()

	await _pinny.appear()
	await _pinny.say(
		["Finally... Your last day is over.", "It's time for your offboarding!"], Pinny.Mood.LAUGH
	)
	await _pinny.say(["So, did you collect $%d?" % level_data.ransom], Pinny.Mood.LAUGH)

	var could_pay := _pay_ransom(level_data)

	if could_pay:
		await get_tree().create_timer(4.0, false).timeout
		await _pinny.say(
			["That's great!", "You've shown incredible individual performances!"], Pinny.Mood.LAUGH
		)
		await _pinny.say(["Sadly..."], Pinny.Mood.NEUTRAL)
		_set_music_muted(true)
		await get_tree().create_timer(4.0, false).timeout
		_set_music_muted(false)
		await _pinny.say(
			[
				"We cannot get your contract extended...",
				"I'm so sorry...",
				"Let's stay connected! I wish you good luck!"
			],
			Pinny.Mood.NEUTRAL
		)
		await _pinny.leave()
		return

	GameState.is_player_dead = true
	_set_music_muted(true)
	await get_tree().create_timer(10.0, false).timeout
	var sentence: Array[String] = ["..."]
	if GameState.total_death() == 0:
		(
			sentence
			. append_array(
				[
					"So, you performed well under pressure, but now that I am nice to you, you just slack off?",
					"Your family will miss you!"
				]
			)
		)
	elif GameState.is_alive(GameState.SON) and not GameState.is_alive(GameState.DAUGHTER):
		sentence.append_array(["You made your son an orphan!"])
	elif not GameState.is_alive(GameState.SON) and GameState.is_alive(GameState.DAUGHTER):
		sentence.append_array(["You made your daughter an orphan!"])
	elif GameState.is_alive(GameState.SON) and GameState.is_alive(GameState.DAUGHTER):
		sentence.append_array(["You made your children orphans!"])
	elif GameState.total_death() == 4:
		sentence.append_array(
			[
				"You are a waste. You bring no value to the company.",
				"I tried to push you upwards with healthy pressure, but you keep slacking off.",
				"Time to join your whole family, pal..."
			]
		)
	else:
		sentence.append_array(["Your performances were mediocre. You are terminated!"])
	await _pinny.say(sentence, Pinny.Mood.ANGRY)

	# Kill cutscene
	var scene_manager := get_tree().current_scene as SceneManager
	if scene_manager:
		scene_manager.play_big_pinny_animation()
	await get_tree().create_timer(1.0, false).timeout
	_pinny.hide()


# MARK: Cutscenes


# Takes the money while Pinny is on screen, then plays the outcome:
# - paid: Pinny says the paid lines and leaves
# - not paid: Pinny says the unpaid lines, leaves, then executes the hostage
func _collect_ransom(
	level_data: LevelData,
	hostage: FamilyMemberData,
	paid: Array[String],
	unpaid: Array[String],
	reveal: Array[String],
	aftermath: Array[String]
) -> void:
	var could_pay := _pay_ransom(level_data)

	await get_tree().create_timer(1.5, false).timeout

	if could_pay:
		await _pinny.say(paid, Pinny.Mood.NEUTRAL)
		await _pinny.leave()
		return

	await _pinny.say(unpaid, Pinny.Mood.NEUTRAL)
	await _pinny.leave()
	await _execute_hostage(hostage, reveal, aftermath)


# Returns whether the player had enough money, takes everything they have otherwise
func _pay_ransom(level_data: LevelData) -> bool:
	var could_pay: bool = GameState.money >= level_data.ransom
	GameState.money = max(0, GameState.money - level_data.ransom)
	return could_pay


# Off screen kill, then Pinny comes back with the photo of the terminated hostage
# reveal: said before the photo, aftermath: said after it
func _execute_hostage(
	hostage: FamilyMemberData, reveal: Array[String], aftermath: Array[String]
) -> void:
	await get_tree().create_timer(0.7, false).timeout

	_set_music_muted(true)

	await get_tree().create_timer(0.5, false).timeout
	await Sfx.play_kill()
	await get_tree().create_timer(0.5, false).timeout
	await Sfx.play_photo()
	await get_tree().create_timer(0.5, false).timeout

	await _pinny.appear()
	await _pinny.say(reveal, Pinny.Mood.NEUTRAL)

	await get_tree().create_timer(0.5, false).timeout

	GameState.kill(hostage)
	_desktop.show_image(hostage.terminated_file_name(), hostage.portrait_terminated)

	await get_tree().create_timer(2.2, false).timeout

	await _pinny.say(aftermath, Pinny.Mood.ANGRY)
	await _pinny.leave()


# Helpers


# Sends the requests until they are all answered or timed out
func _play_day() -> void:
	_running = true
	level_state.is_clock_running = true
	level_state.start_day()
	await day_finished
	print("[DEBUG day-end] day_finished received")

	await get_tree().create_timer(1.0, false).timeout
	print("[DEBUG day-end] timer done, closing windows")

	# The player closes the popup, then the desktop is cleared for the end of day cutscene
	_desktop.locked = true
	_desktop.close_all_windows()
	print("[DEBUG day-end] showing popup")
	await _desktop.show_popup("Youpi", "Your work day is over!", YOUPI_ICON, YOUPI_ICON_16)


# Polled rather than signaled: requests may all be resolved before _play_day(),
# and day_finished must not be emitted before _play_day() awaits it
func _process(_delta: float) -> void:
	if not _running:
		return

	_update_clock()
	if level_state.resolved_requests >= level_state.total_requests:
		_finish_day()
		return

	# Fallback in case a resolution was not counted: look at the notifications themselves
	var resolved_notifications := 0
	for notif in get_tree().get_nodes_in_group(Notification.GROUP):
		if notif.is_resolved():
			resolved_notifications += 1
	if resolved_notifications >= level_state.total_requests:
		push_warning(
			(
				"Day ended by fallback: %d/%d requests counted"
				% [level_state.resolved_requests, level_state.total_requests]
			)
		)
		_finish_day()


func _finish_day() -> void:
	if level_state.is_day_over:
		return

	level_state.is_day_over = true
	_running = false
	level_state.is_clock_running = false
	_update_clock()
	print(
		(
			"[DEBUG day-end] _finish_day %d/%d"
			% [level_state.resolved_requests, level_state.total_requests]
		)
	)
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
	await get_tree().create_timer(0.5, false).timeout


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


func _set_music_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), muted)
