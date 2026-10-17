class_name CategoryClickable
extends Control

signal category_clicked(Category)

var category: Category:
	set(value):
		assert(category == null)
		category = value


@onready var icon: TextureRect = $CenterContainer/Icon
@onready var label: ClickableLabel = $CenterContainer2/Label


func _ready() -> void:
	assert(category != null)
	if category.icon:
		icon.set_texture(category.icon)
	label.set_label_text(category.name, "")
	label.meta_clicked.connect(_on_meta_clicked)


func _on_meta_clicked(_meta: Variant) -> void:
	category_clicked.emit(category)
