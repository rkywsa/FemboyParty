extends Control


@onready var play_button: Button = $CenterContainer/MenuContent/PlayButton


func _ready() -> void:
	play_button.grab_focus()


func _on_play_button_pressed() -> void:
	var error := get_tree().change_scene_to_file("res://Graphics/level.tscn")
	if error != OK:
		push_error("Could not open level scene: %s" % error)
