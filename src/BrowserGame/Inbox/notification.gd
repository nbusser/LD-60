class_name Notification
extends Control

signal timed_out
signal processed(points: int)

const BLINK_COUNT := 2
const TIMEOUT_BLINK_COUNT := 3
const BLINK_INTERVAL := 0.08

@export var request: Request:
	set(value):
		request = value
		if is_node_ready():
			_refresh()
			_start_timer()

var is_timed_out := false

var _time_left := 0.0
var _processed := false

@onready var _query_label: Label = %QueryLabel
@onready var _timer_label: Label = %TimerLabel
@onready var _progress_bar: CustomProgressBar = %ProgressBar
@onready var _link_input: LineEdit = %LinkInput
@onready var _send_button: Button = %SendButton
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	_refresh()
	_start_timer()
	_blink()
	_send_button.pressed.connect(_submit)
	_link_input.text_submitted.connect(_on_link_submitted)
	_link_input.text_changed.connect(_update_send_button)


func _process(delta: float) -> void:
	_time_left = maxf(_time_left - delta, 0.0)
	_update_timer()
	if _time_left <= 0.0:
		_mark_timed_out()


func _refresh() -> void:
	_query_label.text = request.query if request != null else ""


func _start_timer() -> void:
	is_timed_out = false
	_processed = false
	set_process(true)
	_query_label.modulate = Color.WHITE
	_timer_label.modulate = Color.WHITE
	_status_label.text = ""
	_set_editable(true)
	_time_left = request.duration if request != null else 0.0
	_update_timer()


func _update_timer() -> void:
	if is_timed_out or _processed:
		return
	if request == null or request.duration <= 0.0:
		_progress_bar.value = 0.0
		_timer_label.text = ""
		return
	_progress_bar.value = _time_left / request.duration
	_timer_label.text = "%ds" % ceili(_time_left)


func _mark_timed_out() -> void:
	if is_timed_out or _processed:
		return
	is_timed_out = true
	_progress_bar.value = 0.0
	_timer_label.text = "Timed out"
	_timer_label.modulate = Color.DARK_RED
	_query_label.modulate = Color.GRAY
	_set_editable(false)
	_blink(TIMEOUT_BLINK_COUNT)
	timed_out.emit()


func _on_link_submitted(_text: String) -> void:
	_submit()
	_restore_input_focus.call_deferred()


func _restore_input_focus() -> void:
	if _link_input.editable:
		_link_input.grab_focus()


func _submit() -> void:
	if request == null or _processed or is_timed_out:
		return
	if GameState.level_state != null and GameState.level_state.is_day_over:
		return

	var link := _link_input.text.strip_edges()
	if link.is_empty():
		return

	for request_link in request.links:
		if request_link.entry.link == link:
			_accept_link(request_link)
			return

	if Requests.find_entry(link) != null:
		_accept_link(null)
		return

	_set_status("Invalid link", Color.DARK_RED)


func _accept_link(request_link: RequestLink) -> void:
	var points := request_link.points if request_link != null else 0
	_processed = true
	_set_editable(false)
	_progress_bar.value = 1.0
	_timer_label.text = "Done"
	var status_color := Color.DARK_GREEN if points > 0 else Color.GRAY
	_query_label.modulate = status_color
	_set_status("+$%d" % points, status_color)

	GameState.add_money(points)

	processed.emit(points)


func _set_status(text: String, color: Color) -> void:
	_status_label.text = text
	_status_label.modulate = color


func _set_editable(editable: bool) -> void:
	_link_input.editable = editable
	_update_send_button()


func _update_send_button(_text: String = "") -> void:
	_send_button.disabled = (
		not _link_input.editable
		or _processed
		or is_timed_out
		or _link_input.text.strip_edges().is_empty()
	)


func _blink(count: int = BLINK_COUNT) -> void:
	var tween := create_tween()
	for _i in count:
		tween.tween_interval(BLINK_INTERVAL)
		tween.tween_callback(func(): modulate.a = 0.0)
		tween.tween_interval(BLINK_INTERVAL)
		tween.tween_callback(func(): modulate.a = 1.0)
