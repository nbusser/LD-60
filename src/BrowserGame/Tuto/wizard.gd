extends Control

const STEPS: Array[String] = [
	"""[b]Welcome to the Youpi? Setup Wizard[/b]

This wizard will help you learn how to work with your new computer.
It is recommended that you close all other applications before
continuing.""",
	"""[b]Getting Started[/b]

Please read the following information carefully.

- TUTO ICI
- Our friendly assistant Pinny is there to help you.""",
	"""[b]Completing the Youpi? Setup Wizard[/b]

You have successfully completed the Youpi? Setup Wizard.

You may now start working.""",
]

const FOOTERS: Array[String] = [
	"To continue, click Next. To exit the wizard, click Cancel.",
	"To go back, click Back. To continue, click Next.",
	"Click Finish to close this wizard.",
]

const FINISH_MESSAGES: Array[String] = [
	"Installing Youpi? components...",
	"Copying system files...",
	"Configuring your desktop...",
	"Setting up your programs...",
	"Applying final touches...",
	"Finishing installation...",
]

var _step := 0
var _busy := false

@onready var _text: RichTextLabel = %Text
@onready var _footer: Label = %Footer
@onready var _back_button: Button = %BackButton
@onready var _next_button: Button = %NextButton
@onready var _finish_button: Button = %FinishButton
@onready var _cancel_button: Button = %CancelButton
@onready var _cancel_separator: Control = %VSeparator
@onready var _loading: Control = %Loading
@onready var _loading_label: Label = %LoadingLabel


func _ready():
	_back_button.pressed.connect(_on_back_pressed)
	_next_button.pressed.connect(_on_next_pressed)
	_finish_button.pressed.connect(_on_finish_pressed)
	_cancel_button.pressed.connect(_close_window)
	_show_step()


func _show_step():
	_set_buttons_enabled(true)
	_text.text = STEPS[_step]
	_text.scroll_to_line(0)
	_footer.text = FOOTERS[_step]
	var is_last := _step == STEPS.size() - 1
	_back_button.visible = not is_last
	_back_button.disabled = _step == 0
	_cancel_button.visible = not is_last
	_cancel_separator.visible = not is_last
	_next_button.visible = not is_last
	_finish_button.visible = is_last


func _on_back_pressed():
	if _step > 0:
		_step -= 1
		_show_step()


func _on_next_pressed():
	if _busy or _step >= STEPS.size() - 1:
		return
	if _step == STEPS.size() - 2:
		await _install()
	_step += 1
	_show_step()


func _on_finish_pressed():
	GameState.complete_setup()
	_close_window()


func _install() -> void:
	_busy = true
	_loading.visible = true
	_set_buttons_enabled(false)
	var window := _get_window()
	if window != null:
		window.set_busy(true)
	for message in FINISH_MESSAGES:
		_loading_label.text = message
		await get_tree().create_timer(randf_range(0.7, 1.0)).timeout
		GameState.reveal_setup_program()
	_loading.visible = false
	_busy = false
	if window != null:
		window.set_busy(false)


func _set_buttons_enabled(value: bool) -> void:
	for button in [_back_button, _next_button, _finish_button, _cancel_button]:
		button.disabled = not value


func _get_window() -> DesktopWindow:
	var node: Node = get_parent()
	while node != null and not node is DesktopWindow:
		node = node.get_parent()
	return node as DesktopWindow


func _close_window():
	var window := _get_window()
	if window != null:
		window.closed.emit()
