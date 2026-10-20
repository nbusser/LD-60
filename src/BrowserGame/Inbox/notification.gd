class_name Notification
extends PanelContainer

signal timed_out
signal processed(points: int)
signal dismissed

# Polled by the level as a fallback to the signals to end the day
const GROUP := &"notifications"

const BLINK_COUNT := 2
const TIMEOUT_BLINK_COUNT := 3
const BLINK_INTERVAL := 0.08

# Every whitespace and invisible break character that could sneak into a link
# when typing or pasting (including the zero-width spaces EntryClickable
# inserts so links wrap). Removed before matching so links round-trip.
# Includes ASCII \s, unicode spaces, and zero-width/invisible formatting chars.
static var _link_cleaner := RegEx.create_from_string(
	"[\\s\u00a0\u1680\u2000-\u200a\u200b\u200c\u200d\u2028\u2029\u202f\u205f\u2060\ufeff\u3000]"
)

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
@onready var _paste_button: Button = %Button
@onready var _lock_icon: TextureRect = %LockIcon
@onready var _dismiss_button: TextureButton = %DismissButton
@onready var _reset_button: Button = %ResetButton


func _ready() -> void:
	add_to_group(GROUP)
	_refresh()
	_start_timer()
	_blink()
	_send_button.pressed.connect(Sfx.click)
	_send_button.pressed.connect(_submit)
	_link_input.text_submitted.connect(_on_link_submitted)
	_link_input.text_changed.connect(_update_send_button)
	_paste_button.pressed.connect(_on_paste_pressed)
	_dismiss_button.pressed.connect(_on_dismiss_pressed)
	GameState.upgrades_changed.connect(_refresh_paste_lock)
	_refresh_paste_lock()
	_reset_button.pressed.connect(_on_reset_pressed)
	GameState.upgrades_changed.connect(_refresh_reset_button)
	if GameState.level_state != null:
		GameState.level_state.timer_reset_used.connect(_refresh_reset_button)
	_refresh_reset_button()


func _process(delta: float) -> void:
	if not _has_time_limit():
		return
	var time_scale := GameState.level_state.get_time_scale() if GameState.level_state else 1.0
	_time_left = maxf(_time_left - delta * time_scale, 0.0)
	_update_timer()
	if _time_left <= 0.0:
		_mark_timed_out()


# Answered or timed out
func is_resolved() -> bool:
	return _processed or is_timed_out


func _refresh() -> void:
	_query_label.text = request.query if request != null else ""


func _start_timer() -> void:
	is_timed_out = false
	_processed = false
	set_process(true)
	_query_label.modulate = Color.WHITE
	_timer_label.modulate = Color.WHITE
	_status_label.text = ""
	_dismiss_button.visible = false
	_set_editable(true)
	_time_left = request.duration if request != null else 0.0
	_update_timer()


func _update_timer() -> void:
	if is_timed_out or _processed:
		return
	if request == null:
		_progress_bar.value = 0.0
		_timer_label.text = ""
		return
	if not _has_time_limit():
		_progress_bar.value = 1.0
		_timer_label.text = ""
		return
	_progress_bar.value = _time_left / request.duration
	_timer_label.text = "%ds" % ceili(_time_left)


# Requests without a duration never time out (e.g. in the tutorial)
func _has_time_limit() -> bool:
	return request != null and request.duration > 0.0


func _mark_timed_out() -> void:
	if is_timed_out or _processed:
		return
	is_timed_out = true
	_progress_bar.value = 0.0
	_timer_label.text = "Timed out"
	_timer_label.modulate = Color.DARK_RED
	_query_label.modulate = Color.GRAY
	_set_editable(false)
	_refresh_reset_button()
	_blink(TIMEOUT_BLINK_COUNT)
	_show_dismiss_button()
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

	var link := _sanitize_link(_link_input.text)
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
	Sfx.play_error()


# Links are displayed with zero-width spaces (see EntryClickable) so they wrap,
# and other space/invisible characters can sneak in when typing or pasting.
# Strip all of them so the link matches the stored, unmodified value.
func _sanitize_link(text: String) -> String:
	return _link_cleaner.sub(text, "", true)


func _accept_link(request_link: RequestLink) -> void:
	var points := request_link.points if request_link != null else 0
	_processed = true
	_set_editable(false)
	_refresh_reset_button()
	_progress_bar.value = 1.0
	_timer_label.text = "Done"
	var status_color := Color.DARK_GREEN if points > 0 else Color.GRAY
	_query_label.modulate = status_color
	_set_status("+$%d" % points, status_color)

	GameState.add_money(points)

	if points > 0:
		Sfx.play_correct()
	else:
		Sfx.play_wrong()

	_show_dismiss_button()
	processed.emit(points)


func _show_dismiss_button() -> void:
	_dismiss_button.visible = true


func _on_dismiss_pressed() -> void:
	Sfx.click()
	dismissed.emit()
	queue_free()


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
		or _sanitize_link(_link_input.text).is_empty()
	)


func _refresh_paste_lock() -> void:
	var unlocked := GameState.is_upgrade_owned("copy_paste")
	_paste_button.disabled = not unlocked
	_paste_button.modulate.a = 1.0 if unlocked else 0.4
	_lock_icon.visible = not unlocked


# Shown once the upgrade is owned, usable on a single running request per day
func _refresh_reset_button() -> void:
	_reset_button.visible = GameState.is_upgrade_owned("timer_reset")
	var used := GameState.level_state != null and GameState.level_state.is_timer_reset_used
	_reset_button.disabled = used or is_resolved() or not _has_time_limit()
	_reset_button.modulate.a = 0.4 if _reset_button.disabled else 1.0
	_reset_button.tooltip_text = "Already used today" if used else "Reset timer (once a day)"


func _on_reset_pressed() -> void:
	if _reset_button.disabled:
		return
	Sfx.click()
	_time_left = request.duration
	_update_timer()
	_blink()
	if GameState.level_state != null:
		GameState.level_state.use_timer_reset()


func _on_paste_pressed() -> void:
	Sfx.click()
	var clipboard := Globals.clipboard.strip_edges()
	if clipboard.is_empty() or not _link_input.editable:
		return
	_link_input.text = clipboard
	_link_input.caret_column = clipboard.length()
	# setting text from code doesn't emit text_changed
	_update_send_button()


func _blink(count: int = BLINK_COUNT) -> void:
	var tween := create_tween()
	for _i in count:
		tween.tween_interval(BLINK_INTERVAL)
		tween.tween_callback(func(): modulate.a = 0.0)
		tween.tween_interval(BLINK_INTERVAL)
		tween.tween_callback(func(): modulate.a = 1.0)
