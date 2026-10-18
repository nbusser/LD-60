class_name Category
extends Resource

@export var name: String
@export var icon: Texture2D
@export var subcategories: Array[Category]
@export var entries: Array[Entry]


# See assets/data/data.schema.json
static func from_json(data: Dictionary) -> Category:
	var category := Category.new()
	category.name = data["name"]
	if data["icon"] != null:
		category.icon = load(data["icon"])
	assert(
		data.has("subcategories") != data.has("entries"),
		"Category '%s' needs exactly one of 'subcategories' or 'entries'" % category.name
	)
	for sub in data.get("subcategories", []):
		category.subcategories.append(Category.from_json(sub))
	for entry in data.get("entries", []):
		category.entries.append(Entry.from_json(entry))
	return category
