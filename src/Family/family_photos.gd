class_name FamilyPhotos
extends ScrollContainer

const FAMILY_PHOTO_PRELOAD := preload("res://src/Family/family_photo.tscn")

@onready var _entries: VBoxContainer = %Entries


func _ready() -> void:
	for member in GameState.FAMILY:
		var photo: FamilyPhoto = FAMILY_PHOTO_PRELOAD.instantiate()
		photo.member = member
		_entries.add_child(photo)
