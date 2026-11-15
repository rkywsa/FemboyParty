extends Node2D

@onready var backgroundmusic: AudioStreamPlayer2D = $backgroundmusic
@onready var pipebye: AudioStreamPlayer2D = $pipebye
@onready var health_bar: TextureProgressBar = $HUD/HealthBar
@onready var player: CharacterBody2D = $Player
@onready var game_over: Control = $GameOverLayer/GameOver
@onready var restart_button: Button = $GameOverLayer/GameOver/CenterContainer/Menu/RestartButton
@onready var hud: CanvasLayer = $HUD

var coins: int = 0
var coin_label: Label


func _ready() -> void:
	_create_coin_counter()
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	player.health_changed.connect(_on_player_health_changed)
	backgroundmusic.play()
	await get_tree().create_timer(2.38).timeout
	pipebye.play()


func _create_coin_counter() -> void:
	coin_label = Label.new()
	coin_label.name = "CoinsLabel"
	coin_label.position = Vector2(24, 16)
	coin_label.size = Vector2(300, 48)
	coin_label.text = "Coins: %d" % coins
	coin_label.add_theme_font_size_override("font_size", 32)
	coin_label.add_theme_color_override("font_color", Color.WHITE)
	coin_label.add_theme_color_override("font_outline_color", Color.BLACK)
	coin_label.add_theme_constant_override("outline_size", 4)
	coin_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(coin_label)


func add_coin(amount: int = 1) -> void:
	if amount <= 0:
		return

	coins += amount
	if is_instance_valid(coin_label):
		coin_label.text = "Coins: %d" % coins


func _on_player_health_changed(current_health: int, _maximum_health: int) -> void:
	health_bar.value = current_health
	if current_health <= 0 and not game_over.visible:
		game_over.visible = true
		restart_button.grab_focus()
		get_tree().paused = true


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	var error := get_tree().reload_current_scene()
	if error != OK:
		push_error("Could not restart level: %s" % error)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
