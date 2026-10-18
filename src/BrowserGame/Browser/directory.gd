extends Control

const CATEGORY_CLICKABLE_PRELOAD = preload("res://src/BrowserGame/Browser/category_clickable.tscn")
const ENTRY_CLICKABLE_PRELOAD = preload("res://src/BrowserGame/Browser/entry_clickable.tscn")
const DATA: JSON = preload("res://assets/data/data.json")

var selected_category: Category:
	get:
		return _path.back() if _path else null

var _root_categories: Array[Category]
# Categories from the root down to the selected one, used by the back button.
var _path: Array[Category]
var _root_icon: Texture2D
var _root_description: String

@onready var directory = %GridContainer


func _clear_directory() -> void:
	for child in directory.get_children():
		child.queue_free()


func _show(category: Category) -> void:
	%BackArrow.visible = category != null
	if category == null:
		%CategoryIcon.texture = _root_icon
		%CategoryDescription.text = _root_description
		_build_categories(_root_categories)
		return
	%CategoryIcon.texture = category.icon
	%CategoryDescription.text = "[br][br][color=black]" + category.name
	if category.subcategories:
		_build_categories(category.subcategories)
	else:
		_build_category_entries(category.entries)


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
	for data in DATA.data["categories"]:
		_root_categories.append(Category.from_json(data))
	_root_icon = %CategoryIcon.texture
	_root_description = %CategoryDescription.text
	%BackArrow.meta_clicked.connect(func(_meta): _go_back())
	_show(null)


func _category_clicked(category: Category):
	Sfx.click()
	_path.append(category)
	_show(category)


func _go_back() -> void:
	Sfx.click()
	_path.pop_back()
	_show(selected_category)


func _entry_clicked(entry: Entry):
	print("Clicked", entry)
	Sfx.click()
	_path.clear()
	_show(null)
