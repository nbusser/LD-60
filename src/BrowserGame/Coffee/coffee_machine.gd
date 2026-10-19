class_name CoffeeMachine
extends MarginContainer

const BREW_DURATION := 1.5
# How long the timers stay slowed down
const COFFEE_DURATION := 60.0

var _brewing := false

@onready var _label: Label = %Label
@onready var _order_button: Button = %OrderButton


func _ready() -> void:
	_order_button.pressed.connect(_on_order_pressed)
	_refresh()


func _on_order_pressed() -> void:
	var level_state := GameState.level_state
	if _brewing or level_state == null or level_state.is_coffee_drunk:
		return
	Sfx.click()
	_brewing = true
	_refresh()
	Sfx.play_harddrive_short()
	await get_tree().create_timer(BREW_DURATION, false).timeout
	level_state.drink_coffee()
	_brewing = false
	_refresh()
	Sfx.play_slurp()

	await get_tree().create_timer(COFFEE_DURATION, false).timeout
	level_state.end_coffee()
	_refresh()


func _refresh() -> void:
	var level_state := GameState.level_state
	var drunk := level_state != null and level_state.is_coffee_drunk
	if _brewing:
		_label.text = "Brewing..."
	elif drunk and level_state.is_coffee_active:
		_label.text = "Ahh... Time feels slower."
	elif drunk:
		_label.text = "The coffee wore off.\nCome back tomorrow."
	else:
		_label.text = "Fresh coffee, on the house.\nOne per day, lasts %d seconds." % COFFEE_DURATION
	_order_button.disabled = _brewing or drunk
