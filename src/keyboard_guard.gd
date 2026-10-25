extends Node

# Web builds: swallow Ctrl/Cmd+C, V, X so the OS-level clipboard shortcuts
# never reach LineEdits (no native paste of the system clipboard, no browser
# clipboard permission prompts). The in-game clipboard is the only path.
const BLOCKED_KEYS: Array[Key] = [KEY_C, KEY_V, KEY_X]


func _input(event: InputEvent) -> void:
	if not OS.has_feature("web"):
		return
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	if not (key.ctrl_pressed or key.meta_pressed):
		return
	if key.keycode in BLOCKED_KEYS:
		get_viewport().set_input_as_handled()
