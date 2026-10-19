class_name LevelState

extends Resource

signal day_started
signal request_resolved(answered: bool)
signal all_requests_resolved

var level_data: LevelData

var resolved_requests := 0
var total_requests := 0
var is_day_over := false

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
