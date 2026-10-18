class_name Requests

const DATA: JSON = preload("res://assets/data/data.json")

static var _directory_entries: Dictionary[String, Entry] = {}


static func from_json(json: JSON) -> Array[Request]:
	var result: Array[Request] = []
	if json == null or not json.data is Dictionary:
		return result

	var entries_by_link := directory_entries()
	for request_data in json.data.get("requests", []):
		result.append(_request_from_json(request_data, entries_by_link))
	return result


static func directory_entries() -> Dictionary[String, Entry]:
	if _directory_entries.is_empty():
		_directory_entries = _load_directory_entries()
	return _directory_entries


static func find_entry(link: String) -> Entry:
	var entry: Entry = directory_entries().get(link)
	return entry


static func _load_directory_entries() -> Dictionary[String, Entry]:
	var entries: Dictionary[String, Entry] = {}
	for category_data in DATA.data.get("categories", []):
		_collect_entries(Category.from_json(category_data), entries)
	return entries


static func _collect_entries(category: Category, entries: Dictionary[String, Entry]) -> void:
	for entry in category.entries:
		entries[entry.link] = entry
	for subcategory in category.subcategories:
		_collect_entries(subcategory, entries)


static func _request_from_json(
	data: Dictionary, entries_by_link: Dictionary[String, Entry]
) -> Request:
	var request := Request.new()
	request.time = float(data.get("time", 0.0))
	request.query = data["query"]
	request.duration = float(data.get("duration", request.duration))
	for link_data in data.get("links", []):
		var link: String = link_data["link"]
		var entry: Entry = entries_by_link.get(link)
		assert(entry != null, "Request '%s' references unknown entry '%s'" % [request.query, link])
		if entry == null:
			continue
		var request_link := RequestLink.new()
		request_link.entry = entry
		request_link.points = int(link_data.get("points", 1))
		request.links.append(request_link)
	return request
