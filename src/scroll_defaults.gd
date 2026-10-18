extends Node

const DEFAULT_STEP := 16.0


func _ready() -> void:
	get_tree().node_added.connect(_apply_default_step)
	_apply_to_children(get_tree().root)


func _apply_to_children(node: Node) -> void:
	_apply_default_step(node)
	for child in node.get_children():
		_apply_to_children(child)


func _apply_default_step(node: Node) -> void:
	if not (node is ScrollContainer):
		return

	var scroll_container := node as ScrollContainer
	if is_equal_approx(scroll_container.scroll_horizontal_custom_step, -1.0):
		scroll_container.scroll_horizontal_custom_step = DEFAULT_STEP
	if is_equal_approx(scroll_container.scroll_vertical_custom_step, -1.0):
		scroll_container.scroll_vertical_custom_step = DEFAULT_STEP
