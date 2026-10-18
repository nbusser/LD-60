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

var _step := 0

@onready var _text: RichTextLabel = %Text
@onready var _footer: Label = %Footer
@onready var _back_button: Button = %BackButton
@onready var _next_button: Button = %NextButton
@onready var _finish_button: Button = %FinishButton
@onready var _cancel_button: Button = %CancelButton


func _ready():
	_back_button.pressed.connect(_on_back_pressed)
	_next_button.pressed.connect(_on_next_pressed)
	_finish_button.pressed.connect(_on_finish_pressed)
	_cancel_button.pressed.connect(_close_window)
	_show_step()


func _show_step():
	_text.text = STEPS[_step]
	_text.scroll_to_line(0)
	_footer.text = FOOTERS[_step]
	var is_last := _step == STEPS.size() - 1
	_back_button.disabled = _step == 0
	_next_button.visible = not is_last
	_finish_button.visible = is_last


func _on_back_pressed():
	if _step > 0:
		_step -= 1
		_show_step()


func _on_next_pressed():
	if _step < STEPS.size() - 1:
		_step += 1
		_show_step()


func _on_finish_pressed():
	_close_window()


func _close_window():
	var node: Node = get_parent()
	while node != null and not node is DesktopWindow:
		node = node.get_parent()
	if node is DesktopWindow:
		(node as DesktopWindow).closed.emit()
