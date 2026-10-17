@tool
extends Control

const MARGIN = 2
const STEP_WIDTH = 10
const STEP_SPACING = 2

@export_range(0.0, 1.0) var value = 0.0:
	set(_value):
		value = _value
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color.GRAY)
	var steps_to_draw = ceil((size.x - MARGIN) / (STEP_WIDTH + STEP_SPACING) * value)
	for i in steps_to_draw:
		var pos_x = MARGIN + i * (STEP_WIDTH + STEP_SPACING)
		draw_rect(Rect2(pos_x, MARGIN, STEP_WIDTH, size.y - MARGIN * 2), Color.NAVY_BLUE)


func _ready() -> void:
	queue_redraw()
