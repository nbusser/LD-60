class_name LevelData

extends Resource

enum LevelType { BROWSER }

# In this class, put the settings of your level

@export var name := "Level"
@export var timer_duration := 10
@export var type := LevelType.BROWSER
@export var requests_json: JSON
@export var ransom := 10

# Loaded from level json
var requests: Array[Request]


func load_requests() -> void:
	requests = Requests.from_json(requests_json)
