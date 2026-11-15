extends CanvasLayer

var overlay: ColorRect
var panel: PanelContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	build_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	overlay.visible = paused
	panel.visible = paused

func build_menu() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay.add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(-1000,-100)
	panel.scale = Vector2(-10,-10)
	panel.pivot_offset = panel.custom_minimum_size / 2
	panel.visible = false
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUZA"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var resume := Button.new()
	resume.text = "Resume"
	resume.custom_minimum_size = Vector2(180, 42)
	resume.pressed.connect(func():
		get_tree().paused = false
		overlay.visible = false
	)
	vbox.add_child(resume)

	var restart := Button.new()
	restart.text = "Restart"
	restart.custom_minimum_size = Vector2(180, 42)
	restart.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	vbox.add_child(restart)

	var quit := Button.new()
	quit.text = "Quit"
	quit.custom_minimum_size = Vector2(180, 42)
	quit.pressed.connect(func():
		get_tree().paused = false
		get_tree().quit()
	)
	vbox.add_child(quit)
