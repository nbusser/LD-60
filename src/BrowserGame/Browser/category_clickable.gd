class_name CategoryClickable
extends Control

# Path relative to the category shown by this tile, from that category down to
# the clicked one. For example clicking the "Doctors" link under the Health
# tile emits [Health, Doctors], while clicking the tile itself emits [Health].
signal category_clicked(path: Array[Category])

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
		c_label.text = "[color=blue][url]%s[/url][/color]" % c.name
		var subcategory_path: Array[Category] = [category, c]
		c_label.meta_clicked.connect(func(_meta): category_clicked.emit(subcategory_path))
		tags.add_child(c_label)


func _on_meta_clicked(_meta: Variant) -> void:
	var category_path: Array[Category] = [category]
	category_clicked.emit(category_path)
