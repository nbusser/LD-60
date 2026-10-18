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

func _ready() -> void:
	assert(category != null)
	if category.icon:
		icon.set_texture(category.icon)
	label.set_label_text(category.name, "")
	label.meta_clicked.connect(_on_meta_clicked)
	for c in category.subcategories:
		var c_label = RichTextLabel.new()
		c_label.bbcode_enabled = true
		c_label.fit_content = true
		c_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		c_label.text = "[color=blue][url]" + c.name
		c_label.meta_clicked.connect(func(_meta): category_clicked.emit(c))
		tags.add_child(c_label)


func _on_meta_clicked(_meta: Variant) -> void:
	category_clicked.emit(category)
