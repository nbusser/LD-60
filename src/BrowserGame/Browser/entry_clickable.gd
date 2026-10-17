class_name EntryClickable
extends HBoxContainer

signal entry_clicked(Entry)

var entry: Entry:
	set(value):
		assert(entry == null)
		entry = value

@onready var label: ClickableLabel = $ClickableLabel


func _ready() -> void:
	assert(entry != null)
	label.set_label_text(entry.name)
	label.meta_clicked.connect(_on_meta_clicked)


func _on_meta_clicked(_meta: Variant) -> void:
	entry_clicked.emit(entry)
