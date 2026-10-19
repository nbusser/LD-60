class_name LevelState

extends Resource

signal day_started
signal request_resolved(answered: bool)
signal all_requests_resolved
signal coffee_drunk
signal coffee_wore_off
signal timer_reset_used

# Request timers run slower while the coffee of the day is active
const COFFEE_TIME_SCALE := 0.7

var level_data: LevelData

var resolved_requests := 0
var total_requests := 0
var is_day_over := false
# The clock runs, requests are sent according to their time
var is_clock_running := false
# Upgrades usable once a day
var is_coffee_drunk := false
var is_coffee_active := false
var is_timer_reset_used := false

var _started := false


func _init(level_data_p: LevelData):
	self.level_data = level_data_p
	total_requests = level_data_p.requests.size()


func start_day() -> void:
	if _started:
		return
	_started = true
	day_started.emit()
	if total_requests == 0:
		all_requests_resolved.emit()


func drink_coffee() -> void:
	is_coffee_drunk = true
	is_coffee_active = true
	coffee_drunk.emit()


func end_coffee() -> void:
	is_coffee_active = false
	coffee_wore_off.emit()


func use_timer_reset() -> void:
	is_timer_reset_used = true
	timer_reset_used.emit()


# Speed of the request timers
func get_time_scale() -> float:
	return COFFEE_TIME_SCALE if is_coffee_active else 1.0


func has_started() -> bool:
	return _started


func resolve_request(answered: bool) -> void:
	if is_day_over:
		return
	resolved_requests += 1
	if answered:
		GameState.total_requests_answered += 1
	request_resolved.emit(answered)
	if resolved_requests >= total_requests:
		all_requests_resolved.emit()
