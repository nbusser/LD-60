class_name SearchRequest
extends Resource

# A single request received by the human search engine.
@export var text: String
@export var source_ip: String
@export var target: Entry
@export var time_limit := 40.0
