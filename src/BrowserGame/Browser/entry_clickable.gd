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
@onready var copy_button: TextureButton = %Button
@onready var lock_icon: TextureRect = %LockIcon


func _ready() -> void:
	assert(entry != null)
	image.texture = entry.image
	label.set_label_text(
		(
			entry.name
			+ "[br][font=res://assets/fonts/times/timR12.fnt][font_size=12]"
			+ entry.link
			+ "[/font_size][/font]"
		),
		entry.description,
		entry.link
	)
	description.text = entry.description
	label.meta_clicked.connect(_on_meta_clicked)
	copy_button.pressed.connect(_on_copy_pressed)
	GameState.upgrades_changed.connect(_refresh_copy_lock)
	_refresh_copy_lock()


func _on_meta_clicked(_meta: Variant) -> void:
	entry_clicked.emit(entry)


func _refresh_copy_lock() -> void:
	var unlocked := GameState.is_upgrade_owned("copy_paste")
	copy_button.disabled = not unlocked
	copy_button.modulate.a = 1.0 if unlocked else 0.4
	lock_icon.visible = not unlocked


func _on_copy_pressed() -> void:
	# TODO: copy entry.link to clipboard
	pass
