class_name Entry
extends Resource

@export var name: String
@export var link: String
@export var description: String
@export var image: Texture2D


# See assets/data/data.schema.json
static func from_json(data: Dictionary) -> Entry:
	var entry := Entry.new()
	entry.name = data["name"]
	entry.link = data["link"]
	entry.description = data["description"]
	if data["image"] != null:
		entry.image = load(data["image"])
	return entry
