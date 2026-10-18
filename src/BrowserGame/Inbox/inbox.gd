class_name Inbox
extends ScrollContainer

const NOTIFICATION_SCENE = preload("res://src/BrowserGame/Inbox/notification.tscn")

var _elapsed := 0.0

@onready var _notifications: VBoxContainer = %Notifications


func _ready() -> void:
	if GameState.level_state == null:
		return
	for request in GameState.level_state.level_data.requests:
		_schedule_request(request)


func _process(delta: float) -> void:
	_elapsed += delta


func _schedule_request(request: Request) -> void:
	var delay := maxf(request.time - _elapsed, 0.0)
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	_show_request(request)


func _show_request(request: Request) -> void:
	var notif: Notification = NOTIFICATION_SCENE.instantiate()
	notif.request = request
	_notifications.add_child(notif)
	await get_tree().process_frame
