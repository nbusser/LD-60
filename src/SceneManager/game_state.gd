extends Node

signal money_changed(value: int)
signal upgrades_changed
signal family_changed
# Emitted by the setup wizard
signal setup_install_started
signal setup_step_installed
signal setup_completed
# Names of the categories shown in the Youpi? directory, from the root
signal category_browsed(path: PackedStringArray)

var current_level_number := 0
var money := 0:
	set(value):
		money = maxi(value, 0)
		money_changed.emit(money)
var level_state: LevelState

var family := Family.new()
var threatened_member_id: StringName
var last_day_success := false

var owned_upgrades: Dictionary[String, bool] = {}

var total_money_earned := 0
var total_fees_paid := 0
var total_requests_answered := 0


func reset() -> void:
	current_level_number = 0
	money = 0
	level_state = null
	family = Family.new()
	threatened_member_id = &""
	last_day_success = false
	owned_upgrades.clear()
	total_money_earned = 0
	total_fees_paid = 0
	total_requests_answered = 0
	family_changed.emit()
	upgrades_changed.emit()


func threatened_member() -> FamilyMemberData:
	return Family.member(threatened_member_id)


func threatened_name() -> String:
	return Family.name_of(threatened_member_id)


func is_player_threatened() -> bool:
	return threatened_member_id == Family.PLAYER_ID


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
