extends Control

const CATEGORY_CLICKABLE_PRELOAD = preload("res://src/BrowserGame/Browser/category_clickable.tscn")
const ENTRY_CLICKABLE_PRELOAD = preload("res://src/BrowserGame/Browser/entry_clickable.tscn")
const DATA: JSON = preload("res://assets/data/data.json")

var selected_category: Category:
	get:
		return _path.back() if _path else null

var _root_categories: Array[Category]
# Categories from the root down to the selected one (the current location).
var _path: Array[Category]
# Previously visited locations, most recent last. Back restores these instead of
# walking up to the parent category.
var _history: Array[Array] = []
var _root_icon: Texture2D
var _root_description: String

var _scroll_offsets: Dictionary[String, Vector2] = {}
var _restore_generation := 0

@onready var directory = %GridContainer
@onready var _address_bar: LineEdit = %AddressBar
@onready var _back_button: Button = %BackButton
@onready var _home_button: Button = %HomeButton
@onready var _scroll_container: ScrollContainer = %ScrollContainer


func _clear_directory() -> void:
	for child in directory.get_children():
		child.queue_free()


func _show(category: Category) -> void:
	var path := _path_names()
	GameState.category_browsed.emit(path)
	_update_location(path)
	%Logo.visible = category == null
	%CategoryIcon.visible = category != null
	if category == null:
		%CategoryIcon.texture = _root_icon
		%CategoryDescription.text = _root_description
		_build_categories(_root_categories)
	else:
		%CategoryIcon.texture = category.icon
		%CategoryDescription.text = "[br][br][color=black]%s[/color]" % category.name
		_build_category_contents(category)
	_restore_scroll(_location_for(path))


func _path_names() -> PackedStringArray:
	return PackedStringArray(_path.map(func(c: Category): return c.name))


func _location_for(path: PackedStringArray) -> String:
	var location := "youpi://dir.internal"
	if not path.is_empty():
		location += "/" + "/".join(path).replace(" ", "_")
	return location


func _update_location(path: PackedStringArray) -> void:
	_address_bar.text = _location_for(path)
	_back_button.disabled = _history.is_empty()
	_home_button.disabled = path.is_empty()


func _push_history() -> void:
	var snapshot: Array[Category] = []
	snapshot.assign(_path)
	_history.append(snapshot)


func _remember_scroll() -> void:
	_scroll_offsets[_location_for(_path_names())] = Vector2(
		_scroll_container.scroll_horizontal, _scroll_container.scroll_vertical
	)


func _restore_scroll(location: String) -> void:
	_restore_generation += 1
	var generation := _restore_generation
	await get_tree().process_frame
	if generation != _restore_generation or not is_inside_tree():
		return
	var offset: Vector2 = _scroll_offsets.get(location, Vector2.ZERO)
	_scroll_container.scroll_horizontal = int(offset.x)
	_scroll_container.scroll_vertical = int(offset.y)


# A category can have both subcategories and entries of its own.
func _build_category_contents(category: Category) -> void:
	_clear_directory()
	_add_categories(category.subcategories)
	_add_entries(category.entries)


func _build_categories(categories: Array[Category]) -> void:
	_clear_directory()
	_add_categories(categories)


func _add_categories(categories: Array[Category]) -> void:
	for category in categories:
		var category_clickable: CategoryClickable = CATEGORY_CLICKABLE_PRELOAD.instantiate()
		category_clickable.category = category
		category_clickable.category_clicked.connect(_category_clicked)
		directory.add_child(category_clickable)


func _add_entries(entries: Array[Entry]) -> void:
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
	_back_button.pressed.connect(_go_back)
	_home_button.pressed.connect(_go_home)
	_show(null)


func _category_clicked(relative_path: Array[Category]) -> void:
	Sfx.click()
	_remember_scroll()
	_push_history()
	_path.append_array(relative_path)
	_show(selected_category)


func _go_back() -> void:
	if _history.is_empty():
		return
	Sfx.click()
	_remember_scroll()
	var previous_path: Array = _history.pop_back()
	_path.assign(previous_path)
	_show(selected_category)


func _go_home() -> void:
	if _path.is_empty():
		return
	Sfx.click()
	_remember_scroll()
	_push_history()
	_path.clear()
	_show(null)


func _entry_clicked(_entry: Entry):
	Sfx.click()
