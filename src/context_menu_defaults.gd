extends Node


func _ready() -> void:
	get_tree().node_added.connect(_disable_context_menu)
	_apply_to_children(get_tree().root)


func _apply_to_children(node: Node) -> void:
	_disable_context_menu(node)
	for child in node.get_children():
		_apply_to_children(child)


func _disable_context_menu(node: Node) -> void:
	if node is LineEdit:
		(node as LineEdit).context_menu_enabled = false
	elif node is TextEdit:
		(node as TextEdit).context_menu_enabled = false
