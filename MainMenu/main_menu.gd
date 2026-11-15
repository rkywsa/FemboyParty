extends Control

@onready var start_button: Button = $CenterContainer/MenuContent/StartButton
@onready var controls_button: Button = $CenterContainer/MenuContent/ControlsButton
@onready var controls_dialog: AcceptDialog = $ControlsDialog
@onready var buttonsound: AudioStreamPlayer2D = $ButtonSound

var transitioning := false
var menu_buttons: Array[Button] = []
var focus_index := 0
var nav_axis_latched := false


func _ready() -> void:
	menu_buttons = [start_button, controls_button]
	start_button.grab_focus()
	controls_dialog.dialog_text = "STEROWANIE\n\nRuch: A / D lub strzałki\nSkok: Spacja lub A na padzie Xbox\nAtak: lewy przycisk myszy lub B na padzie Xbox\nZmiana broni: 1 / 2 lub RB na padzie Xbox\nPauza: ESC lub przycisk Menu (trzy kreski) na padzie"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_A:
			var focused := get_viewport().gui_get_focus_owner()
			if focused is Button and focused.is_visible_in_tree() and not focused.disabled:
				focused.pressed.emit()
				get_viewport().set_input_as_handled()
		elif event.button_index == JOY_BUTTON_DPAD_UP:
			_move_focus(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == JOY_BUTTON_DPAD_DOWN:
			_move_focus(1)
			get_viewport().set_input_as_handled()
		elif event.button_index in [JOY_BUTTON_B, JOY_BUTTON_BACK]:
			if controls_dialog.visible:
				controls_dialog.hide()
				controls_button.grab_focus()
				get_viewport().set_input_as_handled()
		return

	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_Y:
			if absf(event.axis_value) < 0.3:
				nav_axis_latched = false
			elif not nav_axis_latched and absf(event.axis_value) > 0.65:
				_move_focus(1 if event.axis_value > 0.0 else -1)
				nav_axis_latched = true
				get_viewport().set_input_as_handled()


func _move_focus(direction: int) -> void:
	if controls_dialog.visible:
		return
	focus_index = posmod(focus_index + direction, menu_buttons.size())
	menu_buttons[focus_index].grab_focus()


func _on_start_button_pressed() -> void:
	if transitioning:
		return

	transitioning = true
	start_button.disabled = true
	controls_button.disabled = true
	buttonsound.play()
	await buttonsound.finished

	var error := get_tree().change_scene_to_file("res://Graphics/level.tscn")
	if error != OK:
		transitioning = false
		start_button.disabled = false
		controls_button.disabled = false
		push_error("Could not load level scene: %s" % error)


func _on_controls_button_pressed() -> void:
	controls_dialog.popup_centered()
