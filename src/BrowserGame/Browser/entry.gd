class_name Entry
extends Resource

@export var name: String
@export var link: String
@export var description: String
@export var image: Texture2D


static func from_json(data: Dictionary) -> Entry:
	var entry := Entry.new()
	entry.name = data["name"]
	entry.link = data.get("link", "")
	entry.description = data.get("description", "")
	if data.has("image"):
		entry.image = load(data["image"])
	return entry
