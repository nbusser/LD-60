class_name CategoryClickable
extends Clickable

signal category_clicked(Category)

var category: Category:
	set(value):
		assert(category == null)
		category = value


func _ready() -> void:
	assert(category != null)
	text = "[color=blue][url]" + category.name


func _on_meta_clicked(_meta: Variant) -> void:
	super._on_meta_clicked(_meta)
	category_clicked.emit(category)
