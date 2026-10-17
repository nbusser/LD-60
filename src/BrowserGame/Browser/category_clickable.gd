class_name CategoryClickable
extends Control

signal category_clicked(Category)

var category: Category:
	set(value):
		assert(category == null)
		category = value

@onready var icon: TextureRect = $CenterContainer/Icon
@onready var label: ClickableLabel = $CenterContainer2/Label
@onready var tags: HFlowContainer = $CenterContainer3/Tags
@onready var separator: PackedScene = preload("res://src/BrowserGame/Browser/tag_separator.tscn")

func _ready() -> void:
	assert(category != null)
	if category.icon:
		icon.set_texture(category.icon)
	label.set_label_text(category.name, "")
	label.meta_clicked.connect(_on_meta_clicked)
	var has_tags = false
	for c in category.subcategories:
		has_tags = true
		var c_label = RichTextLabel.new()
		c_label.bbcode_enabled = true
		c_label.fit_content = true
		c_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		c_label.text = "[color=blue][url]" + c.name
		tags.add_child(c_label)
		tags.add_child(separator.instantiate())
	if has_tags:
		tags.get_child(-1).queue_free()


func _on_meta_clicked(_meta: Variant) -> void:
	category_clicked.emit(category)
