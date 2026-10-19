class_name PauseMenu
extends Control

signal resumed


func open() -> void:
	show()
	get_tree().paused = true
	%ResumeButton.grab_focus()


func close() -> void:
	hide()
	get_tree().paused = false
	resumed.emit()


func _on_resume_button_pressed() -> void:
	Sfx.click()
	close()


func _exit_tree() -> void:
	# Never leave the game paused if this overlay goes away while open.
	if get_tree() != null and get_tree().paused:
		get_tree().paused = false
