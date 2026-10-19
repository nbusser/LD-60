class_name FamilyMemberData
extends Resource

@export var id: StringName
@export var display_name: String
@export var file_name: String
@export var portrait: Texture2D
@export var portrait_terminated: Texture2D


func terminated_file_name() -> String:
	return "%s_terminated.%s" % [file_name.get_basename(), file_name.get_extension()]
