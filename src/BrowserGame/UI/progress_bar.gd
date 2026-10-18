@tool
class_name CustomProgressBar
extends Control

const MARGIN = 2
const STEP_WIDTH = 10
const STEP_SPACING = 2
const LOADING_STEP_INTERVAL = 0.1
const LOADING_FILL_RATIO = 0.5

@export_range(0.0, 1.0) var value = 0.0:
	set(_value):
		value = _value
		queue_redraw()

@export var loading := false:
	set(_loading):
		loading = _loading
		_loading_time = 0.0
		queue_redraw()

var _loading_time := 0.0


func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color.GRAY)
	var total_steps = int(ceil((size.x - MARGIN) / (STEP_WIDTH + STEP_SPACING)))
	if total_steps <= 0:
		return

	var first_step = 0
	var steps_to_draw = 0
	if loading:
		first_step = int(_loading_time / LOADING_STEP_INTERVAL)
		steps_to_draw = int(ceil(total_steps * LOADING_FILL_RATIO))
	else:
		steps_to_draw = int(ceil(total_steps * value))

	for i in steps_to_draw:
		var step = (first_step + i) % total_steps
		var pos_x = MARGIN + step * (STEP_WIDTH + STEP_SPACING)
		var width = max(0, min(STEP_WIDTH, size.x - MARGIN - pos_x))
		draw_rect(Rect2(pos_x, MARGIN, width, size.y - MARGIN * 2), Color.NAVY_BLUE)


func _process(delta: float) -> void:
	if not loading:
		return
	_loading_time += delta
	queue_redraw()


func _ready() -> void:
	queue_redraw()
