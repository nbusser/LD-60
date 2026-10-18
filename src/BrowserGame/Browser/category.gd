class_name Category
extends Resource

@export var name: String
@export var icon: Texture2D
@export var subcategories: Array[Category]
@export var entries: Array[Entry]


static func from_json(data: Variant) -> Category:
	var category := Category.new()
	if data is String:
		category.name = data
		return category
	category.name = data["name"]
	if data.has("icon"):
		category.icon = load(data["icon"])
	for sub in data.get("subcategories", []):
		category.subcategories.append(Category.from_json(sub))
	for entry in data.get("entries", []):
		category.entries.append(Entry.from_json(entry))
	return category
