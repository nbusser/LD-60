class_name SearchIndex
extends RefCounted

const DATA: JSON = preload("res://assets/data/data.json")

const MIN_WORD_LENGTH := 3

const STOPWORDS: Dictionary[String, bool] = {
	"a": true,
	"about": true,
	"again": true,
	"all": true,
	"also": true,
	"an": true,
	"and": true,
	"any": true,
	"are": true,
	"as": true,
	"at": true,
	"be": true,
	"been": true,
	"being": true,
	"but": true,
	"by": true,
	"can": true,
	"could": true,
	"d": true,
	"did": true,
	"do": true,
	"does": true,
	"down": true,
	"each": true,
	"few": true,
	"for": true,
	"from": true,
	"had": true,
	"has": true,
	"have": true,
	"he": true,
	"her": true,
	"here": true,
	"him": true,
	"his": true,
	"how": true,
	"i": true,
	"if": true,
	"in": true,
	"into": true,
	"is": true,
	"it": true,
	"its": true,
	"just": true,
	"ll": true,
	"m": true,
	"me": true,
	"more": true,
	"most": true,
	"my": true,
	"no": true,
	"not": true,
	"of": true,
	"off": true,
	"on": true,
	"only": true,
	"or": true,
	"other": true,
	"our": true,
	"out": true,
	"over": true,
	"own": true,
	"re": true,
	"s": true,
	"same": true,
	"she": true,
	"should": true,
	"so": true,
	"some": true,
	"such": true,
	"t": true,
	"than": true,
	"that": true,
	"the": true,
	"their": true,
	"them": true,
	"then": true,
	"these": true,
	"they": true,
	"this": true,
	"those": true,
	"to": true,
	"too": true,
	"under": true,
	"up": true,
	"us": true,
	"ve": true,
	"very": true,
	"was": true,
	"we": true,
	"were": true,
	"what": true,
	"when": true,
	"where": true,
	"which": true,
	"who": true,
	"whom": true,
	"whose": true,
	"why": true,
	"will": true,
	"with": true,
	"would": true,
	"you": true,
	"your": true,
}

var _entries: Array[Entry] = []
var _texts: PackedStringArray = []
var _punctuation := RegEx.new()


func _init() -> void:
	_punctuation.compile("[^\\p{L}\\p{N}]+")
	for category_data in DATA.data.get("categories", []):
		_collect(Category.from_json(category_data))


func search(query: String) -> Array[Entry]:
	var words := query_words(query)
	var result: Array[Entry] = []
	if words.is_empty():
		return result

	for i in _entries.size():
		var text := _texts[i]
		var matches_all := true
		for word in words:
			if not text.contains(word):
				matches_all = false
				break
		if matches_all:
			result.append(_entries[i])
	return result


func query_words(query: String) -> PackedStringArray:
	var words := PackedStringArray()
	for word in _normalize(query).split(" ", false):
		if word.length() < MIN_WORD_LENGTH:
			continue
		if not STOPWORDS.has(word):
			words.append(word)
	return words


func _collect(category: Category) -> void:
	for entry in category.entries:
		_entries.append(entry)
		_texts.append(_normalize(entry.name + " " + entry.description + " " + entry.link))
	for subcategory in category.subcategories:
		_collect(subcategory)


func _normalize(value: String) -> String:
	return _punctuation.sub(value.to_lower(), " ", true).strip_edges()
