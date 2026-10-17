extends Control

@onready var directory = $ScrollContainer/GridContainer

func _ready() -> void:
	for dir in directory.get_children(true):
		var title = dir.get_child(0, true).get_child(0)
		if title:
			title.meta_hover_started.connect(_on_meta_hover_started.bind(title))
			title.meta_hover_ended.connect(_on_meta_hover_ended.bind(title))
			title.meta_clicked.connect(_on_meta_clicked.bind(title))

func _on_meta_hover_started(_meta: Variant, label: Node) -> void:
	label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _on_meta_hover_ended(_meta: Variant, label: Node) -> void:
	label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _on_meta_clicked(_meta: Variant, label: Node) -> void:
	label.text = label.text.replace("=blue", "=purple")
