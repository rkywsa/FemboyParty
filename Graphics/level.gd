extends Node2D

@onready var backgroundmusic: AudioStreamPlayer2D = $backgroundmusic
@onready var pipebye: AudioStreamPlayer2D = $pipebye
@onready var health_bar: TextureProgressBar = $HUD/HealthBar
@onready var player: CharacterBody2D = $Player
@onready var game_over: Control = $GameOverLayer/GameOver
@onready var restart_button: Button = $GameOverLayer/GameOver/CenterContainer/Menu/RestartButton
@onready var quit_button: Button = $GameOverLayer/GameOver/CenterContainer/Menu/QuitButton
@onready var game_over_title: Label = $GameOverLayer/GameOver/CenterContainer/Menu/Title
@onready var coin_label: Label = $HUD/CoinsLabel
@onready var hud: CanvasLayer = $HUD

const END_X: float = 2700.0

var coins: int = 0
var sword_button: Button
var rifle_button: Button
var end_reached := false
var menu_buttons: Array[Button] = []
var menu_focus_index := 0
var menu_axis_latched := false


func _ready() -> void:
	# Keep controller navigation active while death/end screens pause gameplay.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_add_coin_icon()
	_add_weapon_selector()
	_add_finish_portal()
	coin_label.position.x = 64
	coin_label.text = "Coins: %d" % coins
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	player.health_changed.connect(_on_player_health_changed)
	player.weapon_changed.connect(_on_player_weapon_changed)
	_on_player_weapon_changed(player.current_weapon)
	menu_buttons = [restart_button, quit_button]
	backgroundmusic.play()
	await get_tree().create_timer(2.38).timeout
	if is_instance_valid(pipebye):
		pipebye.play()


func _process(_delta: float) -> void:
	if not end_reached and player.global_position.x >= END_X:
		_show_end_screen()


func _unhandled_input(event: InputEvent) -> void:
	if not game_over.visible:
		return

	var viewport := get_viewport()
	if viewport == null:
		return

	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_A:
			var focused := viewport.gui_get_focus_owner()
			if focused is Button and focused.is_visible_in_tree() and not focused.disabled:
				viewport.set_input_as_handled()
				focused.pressed.emit()
		elif event.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_LEFT]:
			viewport.set_input_as_handled()
			_move_game_over_focus(-1)
		elif event.button_index in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT]:
			viewport.set_input_as_handled()
			_move_game_over_focus(1)
		return

	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y:
		if absf(event.axis_value) < 0.3:
			menu_axis_latched = false
		elif not menu_axis_latched and absf(event.axis_value) > 0.65:
			viewport.set_input_as_handled()
			_move_game_over_focus(1 if event.axis_value > 0.0 else -1)
			menu_axis_latched = true


func _move_game_over_focus(direction: int) -> void:
	if menu_buttons.is_empty():
		return
	menu_focus_index = posmod(menu_focus_index + direction, menu_buttons.size())
	menu_buttons[menu_focus_index].grab_focus()


func _add_finish_portal() -> void:
	var portal := Area2D.new()
	portal.name = "FinishPortal"
	portal.position = Vector2(END_X, 198.0)
	portal.collision_layer = 0
	portal.collision_mask = 1
	portal.monitoring = true
	portal.add_to_group("finish_portal")
	add_child(portal)

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(24.0, 64.0)
	shape.shape = rectangle
	portal.add_child(shape)

	var ring := Line2D.new()
	ring.name = "PortalRing"
	ring.width = 3.0
	ring.default_color = Color(0.25, 0.9, 1.0, 1.0)
	ring.antialiased = false
	var points := PackedVector2Array()
	for index in range(17):
		var angle := TAU * float(index) / 16.0
		points.append(Vector2(cos(angle) * 11.0, sin(angle) * 30.0))
	ring.points = points
	portal.add_child(ring)

	var portal_label := Label.new()
	portal_label.text = "EXIT"
	portal_label.position = Vector2(-19.0, -47.0)
	portal_label.add_theme_color_override("font_color", Color(0.5, 0.95, 1.0))
	portal.add_child(portal_label)


func _show_end_screen() -> void:
	end_reached = true
	game_over_title.text = "THE END"
	restart_button.text = "Play Again"
	_show_result_menu()


func _show_result_menu() -> void:
	game_over.visible = true
	game_over.mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().paused = true
	menu_focus_index = 0
	restart_button.grab_focus()


func _add_coin_icon() -> void:
	var coin_icon := TextureRect.new()
	coin_icon.name = "CoinIcon"
	coin_icon.position = Vector2(24, 20)
	coin_icon.size = Vector2(32, 32)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_SCALE

	var coin_atlas := AtlasTexture.new()
	coin_atlas.atlas = load("res://assets/sprites/coin.png")
	coin_atlas.region = Rect2(0, 0, 16, 16)
	coin_icon.texture = coin_atlas
	hud.add_child(coin_icon)


func _add_weapon_selector() -> void:
	var panel := PanelContainer.new()
	panel.name = "WeaponSelector"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 12.0
	panel.offset_top = -132.0
	panel.offset_right = 280.0
	panel.offset_bottom = -12.0
	panel.add_theme_stylebox_override("panel", _make_weapon_panel_style())
	hud.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	panel.add_child(layout)

	var title := Label.new()
	title.text = "WEAPON"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	layout.add_child(title)

	var weapon_row := HBoxContainer.new()
	weapon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	weapon_row.add_theme_constant_override("separation", 8)
	layout.add_child(weapon_row)

	sword_button = _make_weapon_button("SWORD\n[1]")
	rifle_button = _make_weapon_button("GUN\n[2]")
	weapon_row.add_child(_make_weapon_slot(sword_button))
	weapon_row.add_child(_make_weapon_slot(rifle_button))
	sword_button.pressed.connect(player.select_weapon.bind("sword"))
	rifle_button.pressed.connect(player.select_weapon.bind("rifle"))


func _make_weapon_slot(button: Button) -> CenterContainer:
	var slot := CenterContainer.new()
	slot.custom_minimum_size = Vector2(120.0, 72.0)
	slot.add_child(button)
	return slot


func _make_weapon_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(88.0, 48.0)
	button.add_theme_font_size_override("font_size", 12)
	_set_weapon_button_style(button, false)
	return button


func _make_weapon_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.38, 0.38, 0.38, 0.95)
	style.border_color = Color(0.62, 0.62, 0.62, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	return style


func _make_weapon_button_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.62, 0.62, 0.62, 1.0) if selected else Color(0.3, 0.3, 0.3, 0.96)
	style.border_color = Color(0.9, 0.9, 0.9, 1.0) if selected else Color(0.48, 0.48, 0.48, 1.0)
	style.set_border_width_all(3 if selected else 2)
	style.set_corner_radius_all(0)
	style.content_margin_left = 8.0
	style.content_margin_top = 6.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 6.0
	return style


func _on_player_weapon_changed(weapon_name: String) -> void:
	var sword_selected := weapon_name == "sword"
	sword_button.custom_minimum_size = Vector2(104.0, 62.0) if sword_selected else Vector2(88.0, 48.0)
	rifle_button.custom_minimum_size = Vector2(104.0, 62.0) if not sword_selected else Vector2(88.0, 48.0)
	sword_button.add_theme_font_size_override("font_size", 14 if sword_selected else 12)
	rifle_button.add_theme_font_size_override("font_size", 14 if not sword_selected else 12)
	_set_weapon_button_style(sword_button, sword_selected)
	_set_weapon_button_style(rifle_button, not sword_selected)


func _set_weapon_button_style(button: Button, selected: bool) -> void:
	button.add_theme_stylebox_override("normal", _make_weapon_button_style(selected))
	button.add_theme_stylebox_override("hover", _make_weapon_button_style(selected))
	button.add_theme_stylebox_override("pressed", _make_weapon_button_style(selected))
	button.add_theme_stylebox_override("focus", _make_weapon_button_style(selected))


func add_coin(amount: int = 1) -> void:
	if amount <= 0:
		return

	coins += amount
	coin_label.text = "Coins: %d" % coins


func _on_player_health_changed(current_health: int, _maximum_health: int) -> void:
	health_bar.value = current_health
	if current_health <= 0 and not game_over.visible:
		game_over_title.text = "GAME OVER"
		restart_button.text = "Restart"
		_show_result_menu()


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	var error := get_tree().reload_current_scene()
	if error != OK:
		push_error("Could not restart level: %s" % error)


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
