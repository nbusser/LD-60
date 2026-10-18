class_name Notification
extends Control

signal timed_out

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

@onready var _query_label: Label = %QueryLabel
@onready var _timer_label: Label = %TimerLabel
@onready var _progress_bar: CustomProgressBar = %ProgressBar


func _ready() -> void:
	_refresh()
	_start_timer()
	_blink()


func _process(delta: float) -> void:
	_time_left = maxf(_time_left - delta, 0.0)
	_update_timer()
	if _time_left <= 0.0:
		_mark_timed_out()


func _refresh() -> void:
	_query_label.text = request.query if request != null else ""


func _start_timer() -> void:
	is_timed_out = false
	_query_label.modulate = Color.WHITE
	_timer_label.modulate = Color.WHITE
	_time_left = request.duration if request != null else 0.0
	_update_timer()


func _update_timer() -> void:
	if is_timed_out:
		return
	if request == null or request.duration <= 0.0:
		_progress_bar.value = 0.0
		_timer_label.text = ""
		return
	_progress_bar.value = _time_left / request.duration
	_timer_label.text = "%ds" % ceili(_time_left)


func _mark_timed_out() -> void:
	if is_timed_out:
		return
	is_timed_out = true
	_progress_bar.value = 0.0
	_timer_label.text = "Timed out"
	_timer_label.modulate = Color.DARK_RED
	_query_label.modulate = Color.GRAY
	_blink(TIMEOUT_BLINK_COUNT)
	timed_out.emit()


func _blink(count: int = BLINK_COUNT) -> void:
	var tween := create_tween()
	for _i in count:
		tween.tween_interval(BLINK_INTERVAL)
		tween.tween_callback(func(): modulate.a = 0.0)
		tween.tween_interval(BLINK_INTERVAL)
		tween.tween_callback(func(): modulate.a = 1.0)
