class_name Inbox
extends ScrollContainer

const NOTIFICATION_SCENE = preload("res://src/BrowserGame/Inbox/notification.tscn")

var _elapsed := 0.0

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
	_elapsed += delta


func _start_requests() -> void:
	for request in GameState.level_state.level_data.requests:
		_schedule_request(request)


func _schedule_request(request: Request) -> void:
	var delay := maxf(request.time - _elapsed, 0.0)
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if GameState.level_state == null or GameState.level_state.is_day_over:
		return
	_show_request(request)


func _show_request(request: Request) -> void:
	var notif: Notification = NOTIFICATION_SCENE.instantiate()
	notif.request = request
	notif.processed.connect(_on_notification_processed)
	notif.timed_out.connect(_on_notification_timed_out)
	_notifications.add_child(notif)
	await get_tree().process_frame


func _on_notification_processed(_points: int) -> void:
	GameState.level_state.resolve_request(true)


func _on_notification_timed_out() -> void:
	GameState.level_state.resolve_request(false)
