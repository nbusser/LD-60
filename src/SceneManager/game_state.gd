extends Node

signal money_changed(value: int)
signal upgrades_changed
signal family_changed
signal setup_completed

const PLAYER_ID: StringName = &"player"
const FEE_BASE := 20
const FEE_STEP := 15
const FAMILY_MEMBERS: Array[FamilyMemberData] = [
	preload("res://assets/data/family/son.tres"),
	preload("res://assets/data/family/partner.tres"),
	preload("res://assets/data/family/mother.tres"),
	preload("res://assets/data/family/father.tres"),
]

var current_level_number := 0
var money := 0:
	set(value):
		money = maxi(value, 0)
		money_changed.emit(money)
var level_state: LevelState

var day_index := 0
var family_alive: Dictionary[StringName, bool] = {}
var family_death_count := 0
var threatened_member_id: StringName
var protection_fee := 0
var player_dead := false
var setup_complete := false

var owned_upgrades: Dictionary[String, bool] = {}

var total_money_earned := 0
var total_fees_paid := 0
var total_requests_answered := 0

var last_day_success := false
var last_day_fee := 0
var last_day_target_id: StringName

var _day_targets: Array[StringName] = []


func reset() -> void:
	current_level_number = 0
	money = 0
	level_state = null
	day_index = 0
	player_dead = false
	setup_complete = false
	owned_upgrades.clear()
	total_money_earned = 0
	total_fees_paid = 0
	total_requests_answered = 0
	last_day_success = false
	last_day_fee = 0
	last_day_target_id = &""
	_reset_family()
	upgrades_changed.emit()


func start_day(day: int) -> void:
	if family_alive.is_empty():
		_reset_family()

	day_index = day
	if _day_targets.is_empty():
		_build_day_targets()

	if day_index < FAMILY_MEMBERS.size():
		threatened_member_id = _day_targets[day_index]
	else:
		threatened_member_id = PLAYER_ID

	protection_fee = FEE_BASE + FEE_STEP * day_index


func family_member(id: StringName) -> FamilyMemberData:
	for member in FAMILY_MEMBERS:
		if member.id == id:
			return member
	return null


func threatened_member() -> FamilyMemberData:
	return family_member(threatened_member_id)


func threatened_name() -> String:
	if threatened_member_id == PLAYER_ID:
		return "you"
	var member := threatened_member()
	return member.display_name if member != null else "your family"


func is_family_alive(id: StringName) -> bool:
	return family_alive.get(id, false)


func resolve_protection() -> bool:
	last_day_fee = protection_fee
	last_day_target_id = threatened_member_id
	last_day_success = money >= protection_fee

	if last_day_success:
		money -= protection_fee
		total_fees_paid += protection_fee
	else:
		money = 0
		if threatened_member_id == PLAYER_ID:
			player_dead = true
		else:
			family_alive[threatened_member_id] = false
			family_death_count += 1
		family_changed.emit()

	return last_day_success


func needs_setup() -> bool:
	return current_level_number == 0 and not setup_complete


func complete_setup() -> void:
	if setup_complete:
		return
	setup_complete = true
	setup_completed.emit()


func add_money(amount: int) -> void:
	money += amount
	total_money_earned += amount


func is_upgrade_owned(upgrade_id: String) -> bool:
	return owned_upgrades.get(upgrade_id, false)


func try_buy_upgrade(upgrade: UpgradeData) -> bool:
	if upgrade == null or upgrade.id.is_empty():
		return false
	if is_upgrade_owned(upgrade.id):
		return false
	if level_state != null and level_state.is_day_over:
		return false
	if money < upgrade.price:
		return false

	money -= upgrade.price
	owned_upgrades[upgrade.id] = true
	upgrades_changed.emit()
	return true


func _reset_family() -> void:
	family_death_count = 0
	family_alive.clear()
	for member in FAMILY_MEMBERS:
		family_alive[member.id] = true
	_build_day_targets()
	family_changed.emit()


func _build_day_targets() -> void:
	_day_targets.clear()
	for member in FAMILY_MEMBERS:
		_day_targets.append(member.id)
	_day_targets.shuffle()
	_day_targets.append(PLAYER_ID)
