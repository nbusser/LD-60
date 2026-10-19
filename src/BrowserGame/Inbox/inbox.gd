class_name Inbox
extends ScrollContainer

const NOTIFICATION_SCENE = preload("res://src/BrowserGame/Inbox/notification.tscn")

# When the inbox is empty, the next request arrives after a random delay in this range
const EMPTY_INBOX_DELAY_MIN := 1.0
const EMPTY_INBOX_DELAY_MAX := 3.0

var _elapsed := 0.0
# Requests not shown yet, sorted by time
var _upcoming: Array[Request] = []
# Shown requests that are not processed or timed out yet
var _pending := 0
# The next request was already brought forward since the inbox got empty
var _accelerated := false

@onready var _notifications: VBoxContainer = %Notifications


func _ready() -> void:
	if GameState.level_state == null:
		return
	if GameState.level_state.has_started():
		_start_requests()
	else:
		GameState.level_state.day_started.connect(_start_requests, CONNECT_ONE_SHOT)


func _process(delta: float) -> void:
	if GameState.level_state == null or not GameState.level_state.has_started():
		return
	if GameState.level_state.is_day_over:
		return

	# The clock only runs once the day is playing, requests at time 0 arrive before (e.g. in the tutorial)
	if GameState.level_state.is_clock_running:
		_accelerate_if_empty()
		_elapsed += delta

	while not _upcoming.is_empty() and _upcoming[0].time <= _elapsed:
		_show_request(_upcoming.pop_front())


func _start_requests() -> void:
	_upcoming.assign(GameState.level_state.level_data.requests)
	_upcoming.sort_custom(func(a: Request, b: Request): return a.time < b.time)


# Nothing to do for the player: bring the next request closer
func _accelerate_if_empty() -> void:
	if _pending > 0 or _accelerated or _upcoming.is_empty():
		return
	_accelerated = true
	var delay := randf_range(EMPTY_INBOX_DELAY_MIN, EMPTY_INBOX_DELAY_MAX)
	_elapsed = maxf(_elapsed, _upcoming[0].time - delay)


func _show_request(request: Request) -> void:
	var notif: Notification = NOTIFICATION_SCENE.instantiate()
	notif.request = request
	notif.processed.connect(_on_notification_processed)
	notif.timed_out.connect(_on_notification_timed_out)
	_pending += 1
	_accelerated = false
	_notifications.add_child(notif)
	Sfx.play_new_request()
	await get_tree().process_frame


func _on_notification_processed(_points: int) -> void:
	_pending -= 1
	GameState.level_state.resolve_request(true)


func _on_notification_timed_out() -> void:
	_pending -= 1
	GameState.level_state.resolve_request(false)
