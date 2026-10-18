class_name StatsScreen

extends Control

const FAMILY_PHOTO_PRELOAD := preload("res://src/Family/family_photo.tscn")

@onready var _summary: Label = %Summary
@onready var _message: Label = %Message
@onready var _entries: VBoxContainer = %Entries


func _ready() -> void:
	for member in GameState.FAMILY_MEMBERS:
		var photo: FamilyPhoto = FAMILY_PHOTO_PRELOAD.instantiate()
		photo.member = member
		_entries.add_child(photo)

	_summary.text = (
		"Money earned: $%d    Fees paid: $%d    Links answered: %d"
		% [
			GameState.total_money_earned,
			GameState.total_fees_paid,
			GameState.total_requests_answered
		]
	)
	_message.text = _ending_text()


func _ending_text() -> String:
	if GameState.player_dead:
		return "You did not survive the fifth day.\nThe house is quiet, and nobody is coming back."

	match GameState.family_death_count:
		0:
			return "You paid every fee. Your family is safe.\nPinny leaves. For now."
		1:
			return "One photo is crossed out.\nYou tell yourself it was the only way."
		2:
			return "Two empty chairs at dinner.\nYou can still hear their voices in the hallway."
		3:
			return "Only one of them is left.\nYou survived, but the house feels wrong."
		_:
			return "You survived.\nThere is no one left to protect."


func _on_menu_pressed() -> void:
	Globals.end_scene(Globals.EndSceneStatus.STATS_SCREEN_MENU)
