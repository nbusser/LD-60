extends VBoxContainer

const ENTRY_CLICKABLE_PRELOAD = preload("res://src/BrowserGame/Browser/entry_clickable.tscn")
const SEARCH_UPGRADE: UpgradeData = preload("res://assets/data/upgrade/search.tres")
const SEARCH_DELAY := 0.6

var _index: SearchIndex
var _search_timer := Timer.new()
var _pending_query := ""

@onready var _locked_panel: Control = %LockedPanel
@onready var _search_panel: Control = %SearchPanel
@onready var _price_label: Label = %PriceLabel
@onready var _search_input: LineEdit = %SearchInput
@onready var _search_button: Button = %SearchButton
@onready var _clear_button: Button = %ClearButton
@onready var _status_label: Label = %StatusLabel
@onready var _loading_bar: CustomProgressBar = %LoadingBar
@onready var _results: VBoxContainer = %Results


func _ready() -> void:
	_price_label.text = "Price: $%d" % SEARCH_UPGRADE.price
	_search_timer.one_shot = true
	_search_timer.wait_time = SEARCH_DELAY
	_search_timer.timeout.connect(_finish_search)
	add_child(_search_timer)
	_search_button.pressed.connect(Sfx.click)
	_clear_button.pressed.connect(Sfx.click)
	_search_input.text_submitted.connect(_on_search_text_submitted)
	_search_button.pressed.connect(_on_search_pressed)
	_clear_button.pressed.connect(_on_clear_pressed)
	GameState.upgrades_changed.connect(_refresh_unlocked_state)
	_refresh_unlocked_state()


func _refresh_unlocked_state() -> void:
	var unlocked := GameState.is_upgrade_owned(SEARCH_UPGRADE.id)
	_locked_panel.visible = not unlocked
	_search_panel.visible = unlocked
	if not unlocked or _index != null:
		return

	_index = SearchIndex.new()
	_status_label.text = "Click the Search button to start searching."
	_hide_loading()
	_restore_input_focus.call_deferred()


func _start_search() -> void:
	if _index == null:
		return

	var query := _search_input.text
	var words := _index.query_words(query)
	_search_timer.stop()
	_clear_results()

	if query.strip_edges().is_empty():
		_hide_loading()
		_status_label.text = "Type one or more words to search the directory."
		return
	if words.is_empty():
		_hide_loading()
		_status_label.text = "Type at least one word of 3 letters or more."
		return

	_pending_query = query
	_status_label.text = "Searching..."
	_loading_bar.visible = true
	_loading_bar.loading = true
	_search_timer.start()


func _finish_search() -> void:
	if _index == null:
		return

	var entries := _index.search(_pending_query)
	for entry in entries:
		_add_result(entry)
	_hide_loading()
	if entries.is_empty():
		_status_label.text = "No entries found."
		if is_visible_in_tree():
			Sfx.play_error()
	else:
		var noun := "entry" if entries.size() == 1 else "entries"
		_status_label.text = "%d %s found." % [entries.size(), noun]


func _hide_loading() -> void:
	_loading_bar.loading = false
	_loading_bar.visible = false


func _clear_results() -> void:
	for child in _results.get_children():
		_results.remove_child(child)
		child.queue_free()


func _add_result(entry: Entry) -> void:
	var clickable: EntryClickable = ENTRY_CLICKABLE_PRELOAD.instantiate()
	clickable.entry = entry
	# EntryClickable already renders the description inside the clickable label.
	clickable.get_node("%Description").visible = false
	clickable.entry_clicked.connect(_on_entry_clicked)
	_results.add_child(clickable)


func _on_search_text_submitted(_text: String) -> void:
	_start_search()
	_restore_input_focus()
	_restore_input_focus.call_deferred()


func _on_search_pressed() -> void:
	_start_search()
	_restore_input_focus.call_deferred()


func _on_clear_pressed() -> void:
	_search_timer.stop()
	_pending_query = ""
	_search_input.clear()
	_clear_results()
	_hide_loading()
	_status_label.text = "Click the Search button to start searching."
	_restore_input_focus.call_deferred()


func _restore_input_focus() -> void:
	if _search_input.editable:
		_search_input.grab_focus()


func _on_entry_clicked(_entry: Entry) -> void:
	Sfx.click()
