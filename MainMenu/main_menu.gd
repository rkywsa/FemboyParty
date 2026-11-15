extends Control

@onready var start_button: Button = $CenterContainer/MenuContent/StartButton
@onready var buttonsound = $ButtonSound

var transitioning := false


func _ready() -> void:
	start_button.grab_focus()


func _on_start_button_pressed() -> void:
	if transitioning:
		return

	transitioning = true
	start_button.disabled = true

	buttonsound.play()
	await buttonsound.finished
	

	var error := get_tree().change_scene_to_file("res://Graphics/level.tscn")
	if error != OK:
		transitioning = false
		start_button.disabled = false
		push_error("Could not load level scene: %s" % error)
