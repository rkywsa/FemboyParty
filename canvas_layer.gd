extends CanvasLayer

var overlay: ColorRect
var panel: PanelContainer
var controls_label: Label
var menu_buttons: Array[Button] = []
var focus_index := 0
var nav_axis_latched := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	build_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_START:
			toggle_pause()
			get_viewport().set_input_as_handled()
			return

		if not overlay.visible:
			return

		if event.button_index == JOY_BUTTON_A:
			var focused := get_viewport().gui_get_focus_owner()
			if focused is Button and focused.is_visible_in_tree() and not focused.disabled:
				focused.pressed.emit()
				get_viewport().set_input_as_handled()
		elif event.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_LEFT]:
			_move_focus(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT]:
			_move_focus(1)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventJoypadMotion and overlay.visible:
		if event.axis == JOY_AXIS_LEFT_Y:
			if absf(event.axis_value) < 0.3:
				nav_axis_latched = false
			elif not nav_axis_latched and absf(event.axis_value) > 0.65:
				_move_focus(1 if event.axis_value > 0.0 else -1)
				nav_axis_latched = true
				get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	var should_pause := not get_tree().paused
	get_tree().paused = should_pause
	overlay.visible = should_pause
	panel.visible = should_pause
	if should_pause and not menu_buttons.is_empty():
		focus_index = 0
		menu_buttons[focus_index].grab_focus()


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
	panel.custom_minimum_size = Vector2(380, 360)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUZA"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var controls_button := _make_button("Sterowanie")
	controls_button.pressed.connect(_toggle_controls)
	vbox.add_child(controls_button)
	menu_buttons.append(controls_button)

	controls_label = Label.new()
	controls_label.text = "Ruch: lewy drążek / A-D / strzałki\nSkok: A / Spacja\nAtak: B / lewy przycisk myszy\nZmiana broni: RB / 1 / 2\nPauza: przycisk Menu (trzy kreski) / Esc"
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_label.visible = false
	vbox.add_child(controls_label)

	var resume := _make_button("Wznów")
	resume.pressed.connect(func():
		_set_paused(false)
	)
	vbox.add_child(resume)
	menu_buttons.append(resume)

	var restart := _make_button("Restart")
	restart.pressed.connect(func():
		_set_paused(false)
		get_tree().reload_current_scene()
	)
	vbox.add_child(restart)
	menu_buttons.append(restart)

	var quit := _make_button("Wyjdź")
	quit.pressed.connect(func():
		_set_paused(false)
		get_tree().quit()
	)
	vbox.add_child(quit)
	menu_buttons.append(quit)


func _make_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(240, 42)
	button.focus_mode = Control.FOCUS_ALL
	return button


func _move_focus(direction: int) -> void:
	if menu_buttons.is_empty():
		return
	focus_index = posmod(focus_index + direction, menu_buttons.size())
	menu_buttons[focus_index].grab_focus()


func _toggle_controls() -> void:
	controls_label.visible = not controls_label.visible


func _set_paused(should_pause: bool) -> void:
	get_tree().paused = should_pause
	overlay.visible = should_pause
	panel.visible = should_pause
