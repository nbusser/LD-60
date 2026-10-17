class_name RequestItem
extends PanelContainer

# A request card in the inbox. Owns its own countdown.

signal selected(item)
signal timed_out(item)
signal closed(item)

const COLOR_HEADER_NEW := Color(0.65, 0.0, 0.0)
const COLOR_HEADER_DONE := Color(0.1, 0.45, 0.1)
const COLOR_HEADER_FAILED := Color(0.55, 0.0, 0.0)
const COLOR_STATUS_OK := Color(0.1, 0.45, 0.1)
const COLOR_STATUS_TIMEOUT := Color(0.6, 0.05, 0.05)
const COLOR_SEGMENT_FILLED := Color(0, 0, 0.501961)
const COLOR_SEGMENT_EMPTY := Color(0.82, 0.82, 0.82)
const SEGMENT_COUNT := 20

var request: SearchRequest

var _time_left := 0.0
var _resolved := false
var _is_selected := false
var _segments: Array[ColorRect] = []
var _style_base: StyleBoxFlat
var _style_selected: StyleBoxFlat
var _style_success: StyleBoxFlat
var _style_timeout: StyleBoxFlat

@onready var _header: Label = %Header
@onready var _time_label: Label = %Time
@onready var _request_text: Label = %RequestText
@onready var _source_ip: Label = %SourceIp
@onready var _segment_bar: HBoxContainer = %SegmentBar
@onready var _status: Label = %Status
@onready var _close_button: Button = %Close


func _ready() -> void:
	assert(request != null, "A RequestItem needs a SearchRequest before being added to the tree")

	_style_base = _make_card_style(Color(0.97, 0.97, 0.97), Color(0.45, 0.45, 0.45))
	_style_selected = _make_card_style(Color(0.85, 0.9, 0.98), Color(0.0, 0.0, 0.5))
	_style_success = _make_card_style(Color(0.85, 0.95, 0.85), Color(0.1, 0.45, 0.1))
	_style_timeout = _make_card_style(Color(0.96, 0.86, 0.86), Color(0.55, 0.0, 0.0))
	_build_segments()
	_close_button.pressed.connect(_on_close_pressed)

	_request_text.text = request.text
	_source_ip.text = "IP: " + request.source_ip
	_time_left = maxf(request.time_limit, 0.1)
	_status.visible = false
	_apply_style(_style_base)
	_update_timer_ui()


func _process(delta: float) -> void:
	if _resolved:
		return

	_time_left = maxf(_time_left - delta, 0.0)
	_update_timer_ui()

	if _time_left <= 0.0:
		_fail_timeout()


func set_selected(value: bool) -> void:
	if _resolved:
		return
	if _is_selected == value:
		return

	_is_selected = value
	_apply_style(_style_selected if value else _style_base)


func mark_success() -> void:
	if _resolved:
		return

	_resolved = true
	set_process(false)
	_header.text = "REQUEST SERVED"
	_header.add_theme_color_override("font_color", COLOR_HEADER_DONE)
	_status.text = "200 OK"
	_status.add_theme_color_override("font_color", COLOR_STATUS_OK)
	_status.visible = true
	_time_label.text = "OK"
	_render_segments(SEGMENT_COUNT, COLOR_SEGMENT_FILLED)
	_apply_style(_style_success)
	_close_button.visible = true
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func is_resolved() -> bool:
	return _resolved


func _on_close_pressed() -> void:
	closed.emit(self)


func _gui_input(event: InputEvent) -> void:
	if _resolved:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			selected.emit(self)
			accept_event()


func _fail_timeout() -> void:
	if _resolved:
		return

	_resolved = true
	set_process(false)
	_header.text = "REQUEST FAILED"
	_header.add_theme_color_override("font_color", COLOR_HEADER_FAILED)
	_status.text = "408 Request Timeout"
	_status.add_theme_color_override("font_color", COLOR_STATUS_TIMEOUT)
	_status.visible = true
	_time_label.text = "0s"
	_render_segments(0, COLOR_SEGMENT_FILLED)
	_apply_style(_style_timeout)
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	timed_out.emit(self)


func _update_timer_ui() -> void:
	var ratio := _time_left / maxf(request.time_limit, 0.1)
	var filled := ceili(ratio * SEGMENT_COUNT)
	_time_label.text = "%ds" % ceili(_time_left)
	_render_segments(filled, COLOR_SEGMENT_FILLED)


func _build_segments() -> void:
	for _i in range(SEGMENT_COUNT):
		var segment := ColorRect.new()
		segment.custom_minimum_size = Vector2(0, 10)
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_segment_bar.add_child(segment)
		_segments.append(segment)


func _render_segments(filled: int, color: Color) -> void:
	for i in range(_segments.size()):
		_segments[i].color = color if i < filled else COLOR_SEGMENT_EMPTY


func _apply_style(style: StyleBoxFlat) -> void:
	add_theme_stylebox_override("panel", style)


func _make_card_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	return style
