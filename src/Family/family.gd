class_name Family
extends RefCounted

## One run's family: who gets threatened each day and who is dead.
## The player is the last target, after every family member.

const PLAYER_ID: StringName = &"player"
const MEMBERS: Array[FamilyMemberData] = [
	preload("res://assets/data/family/father.tres"),
	preload("res://assets/data/family/mother.tres"),
	preload("res://assets/data/family/son.tres"),
	preload("res://assets/data/family/daughter.tres"),
]

var _targets: Array[StringName] = []
var _dead: Dictionary[StringName, bool] = {}


func _init() -> void:
	for member in MEMBERS:
		_targets.append(member.id)
	_targets.shuffle()
	_targets.append(PLAYER_ID)


static func member(id: StringName) -> FamilyMemberData:
	for m in MEMBERS:
		if m.id == id:
			return m
	return null


## Display name of a target, "you" for the player.
static func name_of(id: StringName) -> String:
	var m := member(id)
	return m.display_name if m != null else "you"


func target_for_day(day: int) -> StringName:
	return _targets[mini(day, _targets.size() - 1)]


func is_alive(id: StringName) -> bool:
	return not _dead.has(id)


func kill(id: StringName) -> void:
	_dead[id] = true


func is_player_dead() -> bool:
	return not is_alive(PLAYER_ID)


func dead_member_count() -> int:
	return _dead.size() - (1 if is_player_dead() else 0)
