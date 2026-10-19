class_name FamilyPhoto
extends HBoxContainer

@export var member: FamilyMemberData:
	set(value):
		member = value
		if is_node_ready():
			_refresh()

@onready var _photo: TextureRect = %Photo
@onready var _file_name: Label = %FileName


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

	var alive := GameState.is_alive(member)
	_photo.texture = member.portrait if alive else member.portrait_terminated
	_file_name.text = member.file_name if alive else member.terminated_file_name()
