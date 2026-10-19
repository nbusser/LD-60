class_name DesktopSelectionRect
extends Control

const FILL_COLOR := Color("#00808066")
const BORDER_COLOR := Color.WHITE
const BORDER_DOT_SIZE := 1

var selection_rect := Rect2():
	set(value):
		selection_rect = value
		queue_redraw()


func _draw() -> void:
	var rect := selection_rect.abs()
	if rect.size == Vector2.ZERO:
		return

	draw_rect(rect, FILL_COLOR)
	_draw_dotted_border(rect)


# Dots are anchored to even pixels on a fixed checkerboard grid, so they stay in
# place while the rectangle is resized instead of reflowing along the border.
func _draw_dotted_border(rect: Rect2) -> void:
	var left := roundi(rect.position.x)
	var top := roundi(rect.position.y)
	var right := roundi(rect.position.x + rect.size.x)
	var bottom := roundi(rect.position.y + rect.size.y)

	for x in range(left, right + 1):
		if x % 2 == 0:
			_draw_dot(x, top)
			_draw_dot(x, bottom)
	for y in range(top + 1, bottom):
		if y % 2 == 0:
			_draw_dot(left, y)
			_draw_dot(right, y)


func _draw_dot(x: int, y: int) -> void:
	draw_rect(Rect2(x, y, BORDER_DOT_SIZE, BORDER_DOT_SIZE), BORDER_COLOR)


func clear() -> void:
	selection_rect = Rect2()
