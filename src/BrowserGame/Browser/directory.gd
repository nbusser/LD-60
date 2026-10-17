extends Control

const CATEGORY_CLICKABLE_PRELOAD = preload("res://src/BrowserGame/Browser/category_clickable.tscn")
const ENTRY_CLICKABLE_PRELOAD = preload("res://src/BrowserGame/Browser/entry_clickable.tscn")

@export var root_categories: Array[Category]

var selected_category: Category:
	set(category):
		if category == null:
			_build_categories(root_categories)
		else:
			if len(category.subcategories):
				_build_categories(category.subcategories)
			else:
				_build_category_entries(category.entries)

@onready var directory = $Grid


func _clear_directory() -> void:
	for child in directory.get_children():
		child.queue_free()


func _build_categories(categories: Array[Category]) -> void:
	_clear_directory()

	for category in categories:
		var category_clickable: CategoryClickable = CATEGORY_CLICKABLE_PRELOAD.instantiate()
		category_clickable.category = category
		category_clickable.category_clicked.connect(_category_clicked)
		directory.add_child(category_clickable)


func _build_category_entries(entries: Array[Entry]) -> void:
	_clear_directory()

	for entry in entries:
		var entry_clickable: EntryClickable = ENTRY_CLICKABLE_PRELOAD.instantiate()
		entry_clickable.entry = entry
		entry_clickable.entry_clicked.connect(_entry_clicked)
		directory.add_child(entry_clickable)


func _ready() -> void:
	selected_category = null


func _category_clicked(category: Category):
	selected_category = category


func _entry_clicked(entry: Entry):
	print("Clicked", entry)
	selected_category = null
