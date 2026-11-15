extends CanvasLayer

var overlay: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	var should_pause := not get_tree().paused
	get_tree().paused = should_pause
	overlay.visible = should_pause

func _build_menu() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	panel.add_child(buttons)

	var title := Label.new()
	title.text = "Pauza"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buttons.add_child(title)

	var resume_button := Button.new()
	resume_button.text = "Resume"
	resume_button.pressed.connect(_resume)
	buttons.add_child(resume_button)

	var restart_button := Button.new()
	restart_button.text = "Restart"
	restart_button.pressed.connect(_restart)
	buttons.add_child(restart_button)

	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.pressed.connect(_quit)
	buttons.add_child(quit_button)

func _resume() -> void:
	get_tree().paused = false
	overlay.visible = false

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _quit() -> void:
	get_tree().paused = false
	get_tree().quit()
