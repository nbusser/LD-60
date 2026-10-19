class_name FamilyPhoto
extends HBoxContainer

@export var member: FamilyMemberData:
	set(value):
		member = value
		if is_node_ready():
			_refresh()

@onready var _photo: TextureRect = %Photo
@onready var _file_name: Label = %FileName
@onready var _status: Label = %Status


func _ready() -> void:
	GameState.family_changed.connect(_refresh)
	_refresh()


func _gui_input(event: InputEvent) -> void:
	if (
		member != null
		and event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		Desktop.find_from(self).show_image(_file_name.text, _photo.texture)


func _refresh() -> void:
	if member == null:
		return

	var alive := GameState.family.is_alive(member.id)
	_photo.texture = member.portrait if alive else member.portrait_terminated
	_file_name.text = member.file_name if alive else _terminated_name(member.file_name)

	if not alive:
		_status.text = "TERMINATED"
		_status.modulate = Color.DARK_RED
	elif GameState.threatened_member_id == member.id:
		_status.text = "PROTECTED TODAY"
		_status.modulate = Color.DARK_GOLDENROD
	else:
		_status.text = member.relation
		_status.modulate = Color.DIM_GRAY


func _terminated_name(file_name: String) -> String:
	var extension := file_name.get_extension()
	return "%s_terminated.%s" % [file_name.get_basename(), extension]
