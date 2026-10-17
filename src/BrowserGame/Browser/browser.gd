class_name BrowserGame
extends Control

# Desktop screen for the human search engine. Left: inbox with timed requests.
# Right: old HTTP directory used to answer them.

const REQUEST_ITEM_PRELOAD = preload("res://src/BrowserGame/request_item.tscn")
const DEFAULT_REQUESTS = [
	preload("res://assets/data/request/back_pain.tres"),
	preload("res://assets/data/request/zouk_therapy.tres"),
	preload("res://assets/data/request/cheap_shirt.tres"),
]

var _requests: Array[SearchRequest] = []
var _selected_item: RequestItem = null
var _next_request_index := 0
var _served := 0
var _timed_out := 0

@onready var _mail_title: Label = %MailTitle
@onready var _request_list: VBoxContainer = %RequestList
@onready var _mail_status: Label = %MailStatus
@onready var _inbox_scroll: ScrollContainer = %MailScroll
@onready var _browser_status: Label = %BrowserStatus
@onready var _page_header: Label = %PageHeader
@onready var _path_label: Label = %PathLabel
@onready var _directory: DirectoryPanel = %Directory
@onready var _arrival_timer: Timer = $ArrivalTimer


func init(level_data: LevelData) -> void:
	_requests = level_data.requests.duplicate()


func _ready() -> void:
	if _requests.is_empty():
		for request in DEFAULT_REQUESTS:
			_requests.append(request)

	_directory.entry_selected.connect(_on_entry_selected)
	_directory.path_changed.connect(_on_path_changed)
	%BackButton.pressed.connect(_on_back_pressed)
	%IndexButton.pressed.connect(_on_index_pressed)
	_arrival_timer.timeout.connect(_show_next_request)

	_on_path_changed("/")
	_show_next_request()


func _show_next_request() -> void:
	if _next_request_index >= _requests.size():
		return

	var request: SearchRequest = _requests[_next_request_index]
	_next_request_index += 1

	var item: RequestItem = REQUEST_ITEM_PRELOAD.instantiate()
	item.request = request
	item.selected.connect(_on_request_selected)
	item.timed_out.connect(_on_request_timed_out)
	item.closed.connect(_on_request_closed)
	_request_list.add_child(item)

	_browser_status.text = "New request received - select it, then find an entry."
	_update_summary()
	_scroll_inbox_to_bottom.call_deferred()

	if _next_request_index < _requests.size():
		_arrival_timer.start()


func _on_request_selected(item: RequestItem) -> void:
	if item == _selected_item:
		return

	if is_instance_valid(_selected_item):
		_selected_item.set_selected(false)

	_selected_item = item
	item.set_selected(true)
	_browser_status.text = "Request selected - find a matching entry."


func _on_entry_selected(entry: Entry) -> void:
	if _selected_item == null:
		_browser_status.text = "Select a request first."
		return

	if entry == _selected_item.request.target:
		_selected_item.mark_success()
		_served += 1
		_selected_item = null
		_browser_status.text = "200 OK - entry delivered."
		_after_resolution()
	else:
		_browser_status.text = "No match. Keep looking."


func _on_request_timed_out(item: RequestItem) -> void:
	_timed_out += 1
	if _selected_item == item:
		_selected_item = null
	_browser_status.text = "408 Request Timeout"
	_after_resolution()


func _on_request_closed(item: RequestItem) -> void:
	if _selected_item == item:
		_selected_item = null
	_request_list.remove_child(item)
	item.queue_free()


func _after_resolution() -> void:
	_update_summary()
	_check_complete()


func _on_path_changed(path: String) -> void:
	_path_label.text = "http://directory.local" + path
	_page_header.text = "Index of " + path
	_browser_status.text = "Done."


func _on_back_pressed() -> void:
	_directory.go_back()


func _on_index_pressed() -> void:
	_directory.show_root()


func _update_summary() -> void:
	var resolved := _served + _timed_out
	var pending := _requests.size() - resolved
	if pending <= 0:
		_mail_title.text = "Inbox - shift complete"
	else:
		var suffix := "request" if pending == 1 else "requests"
		_mail_title.text = "Inbox - %d new %s" % [pending, suffix]

	_mail_status.text = (
		"Served: %d    Timed out: %d    Pending: %d" % [_served, _timed_out, pending]
	)


func _scroll_inbox_to_bottom() -> void:
	_inbox_scroll.scroll_vertical = int(_inbox_scroll.get_v_scroll_bar().max_value)


func _check_complete() -> void:
	var all_arrived := _next_request_index >= _requests.size()
	if all_arrived and _served + _timed_out >= _requests.size():
		_browser_status.text = "Done. Shift complete."
