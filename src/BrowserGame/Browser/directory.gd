class_name DirectoryPanel
extends Control

# Old-fashioned HTTP directory. Emits the clicked entry so the game can use it
# as an answer, and tracks the current path for the browser chrome.

signal entry_selected(entry: Entry)
signal path_changed(path: String)

const CATEGORY_CLICKABLE_PRELOAD = preload("res://src/BrowserGame/Browser/category_clickable.tscn")
const ENTRY_CLICKABLE_PRELOAD = preload("res://src/BrowserGame/Browser/entry_clickable.tscn")

@export var root_categories: Array[Category]

var _category_stack: Array[Category] = []

@onready var directory = $ScrollContainer/List


func _ready() -> void:
	show_root()


func show_root() -> void:
	_category_stack.clear()
	_rebuild()


func go_back() -> void:
	if _category_stack.is_empty():
		return
	_category_stack.pop_back()
	_rebuild()


func _rebuild() -> void:
	_clear_directory()

	if _category_stack.is_empty():
		_build_categories(root_categories)
	else:
		var current: Category = _category_stack.back()
		if len(current.subcategories):
			_build_categories(current.subcategories)
		else:
			_build_category_entries(current.entries)

	path_changed.emit(_current_path())


func _current_path() -> String:
	if _category_stack.is_empty():
		return "/"

	var parts := PackedStringArray()
	for category in _category_stack:
		parts.append(category.name)
	return "/" + "/".join(parts) + "/"


func _clear_directory() -> void:
	for child in directory.get_children():
		directory.remove_child(child)
		child.queue_free()


func _build_categories(categories: Array[Category]) -> void:
	for category in categories:
		var category_clickable: CategoryClickable = CATEGORY_CLICKABLE_PRELOAD.instantiate()
		category_clickable.category = category
		category_clickable.category_clicked.connect(_category_clicked)
		directory.add_child(category_clickable)


func _build_category_entries(entries: Array[Entry]) -> void:
	for entry in entries:
		var entry_clickable: EntryClickable = ENTRY_CLICKABLE_PRELOAD.instantiate()
		entry_clickable.entry = entry
		entry_clickable.entry_clicked.connect(_entry_clicked)
		directory.add_child(entry_clickable)


func _category_clicked(category: Category) -> void:
	_category_stack.append(category)
	_rebuild()


func _entry_clicked(entry: Entry) -> void:
	entry_selected.emit(entry)
