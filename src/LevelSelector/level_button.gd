class_name LevelButton

extends Button

signal level_clicked(level: int)

var level_number: int


func init(level_data: LevelData, id_level: int) -> void:
	self.level_number = id_level
	self.text = level_data.name


func _on_pressed() -> void:
	level_clicked.emit(self.level_number)
