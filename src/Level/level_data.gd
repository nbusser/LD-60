class_name LevelData

extends Resource

enum LevelType { BROWSER }

# In this class, put the settings of your level

@export var name := "Level"
# Tutorial levels have no timer, no threat and no protection fee
@export var is_tutorial := false
# Day of the week, drives Pinny's threat and the fee. Ignored for tutorials.
@export var day_index := 0
@export var timer_duration := 10
@export var type := LevelType.BROWSER
@export var requests_json: JSON

# Loaded from level json
var requests: Array[Request]


func load_requests() -> void:
	requests = Requests.from_json(requests_json)
