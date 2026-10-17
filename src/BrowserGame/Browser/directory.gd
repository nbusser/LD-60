extends Control

@export var categories: Array[Category]

var category_clickable_preload = preload("res://src/BrowserGame/Browser/category_clickable.tscn")

var _categories_to_label: Dictionary[Category, RichTextLabel]

@onready var directory = $ScrollContainer/GridContainer


func _build_categories() -> void:
	assert(_categories_to_label.is_empty())
	for category in categories:
		var category_clickable: CategoryClickable = category_clickable_preload.instantiate()
		category_clickable.category = category
		$ScrollContainer.add_child(category_clickable)


func _ready() -> void:
	_build_categories()
