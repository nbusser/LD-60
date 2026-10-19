class_name EntryClickable
extends HBoxContainer

signal entry_clicked(Entry)

# Web exports do not break overlong words with AUTOWRAP_WORD_SMART, so long
# URLs would overflow their entry. Zero-width spaces give the text server
# break opportunities without changing how the link reads or is copied.
const ZERO_WIDTH_SPACE := "\u200b"
const URL_BREAK_CHARS := ["-", ".", "/", "_", ":", "?", "&", "=", "@", "+"]
const MAX_URL_SEGMENT := 24

var entry: Entry:
	set(value):
		assert(entry == null)
		entry = value

@onready var image: TextureRect = $Left/Image
@onready var label: ClickableLabel = %NameAndLink
@onready var description: Label = %Description
@onready var copy_button: Button = %Button
@onready var _copy_margin: MarginContainer = $Left/CopyMargin


func _ready() -> void:
	assert(entry != null)
	image.texture = entry.image
	label.set_label_text(
		(
			entry.name
			+ "[br][font=res://assets/fonts/times/timR12.fnt][font_size=12]"
			+ _make_link_breakable(entry.link)
			+ "[/font_size][/font]"
		),
		entry.description,
		entry.link
	)
	#description.text = entry.description
	label.meta_clicked.connect(_on_meta_clicked)
	copy_button.pressed.connect(_on_copy_pressed)
	GameState.upgrades_changed.connect(_refresh_copy_lock)
	_refresh_copy_lock()


func _make_link_breakable(link: String) -> String:
	var result := ""
	var segment_length := 0
	for i in link.length():
		var character := link[i]
		result += character
		segment_length += 1
		if character in URL_BREAK_CHARS or segment_length >= MAX_URL_SEGMENT:
			result += ZERO_WIDTH_SPACE
			segment_length = 0
	return result


func _on_meta_clicked(_meta: Variant) -> void:
	entry_clicked.emit(entry)


func _refresh_copy_lock() -> void:
	_copy_margin.visible = GameState.is_upgrade_owned("copy_paste")


func _on_copy_pressed() -> void:
	Globals.clipboard = entry.link
	Sfx.click()
	var desktop := Desktop.find_from(self)
	if desktop != null:
		desktop.show_cursor_popup("Copied")
