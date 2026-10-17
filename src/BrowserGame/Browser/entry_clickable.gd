class_name EntryClickable
extends HBoxContainer

signal entry_clicked(Entry)

var entry: Entry:
	set(value):
		assert(entry == null)
		entry = value


@onready var image: TextureRect = $Image
@onready var label: ClickableLabel = %NameAndLink
@onready var description: Label = %Description

func _ready() -> void:
	assert(entry != null)
	image.texture = entry.image
	label.set_label_text(entry.name + " " + entry.link)
	description.text = entry.description
	label.meta_clicked.connect(_on_meta_clicked)


func _on_meta_clicked(_meta: Variant) -> void:
	entry_clicked.emit(entry)
