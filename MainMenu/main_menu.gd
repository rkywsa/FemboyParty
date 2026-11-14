extends Control


@onready var start_button: Button = $CenterContainer/MenuContent/StartButton


func _ready() -> void:
	start_button.grab_focus()


func _on_start_button_pressed() -> void:
	var error := get_tree().change_scene_to_file("res://Graphics/level.tscn")
	if error != OK:
		push_error("Could not load level scene: %s" % error)
