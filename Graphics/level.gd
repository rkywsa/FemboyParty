extends Node2D

@onready var backgroundmusic: AudioStreamPlayer2D = $backgroundmusic
@onready var pipebye: AudioStreamPlayer2D = $pipebye
@onready var health_bar: TextureProgressBar = $HUD/HealthBar
@onready var player: CharacterBody2D = $Player
@onready var game_over: Control = $GameOverLayer/GameOver
@onready var restart_button: Button = $GameOverLayer/GameOver/CenterContainer/Menu/RestartButton
@onready var coin_label: Label = $HUD/CoinsLabel
@onready var hud: CanvasLayer = $HUD

var coins: int = 0


func _ready() -> void:
	_add_coin_icon()
	coin_label.position.x = 64
	coin_label.text = "Coins: %d" % coins
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	player.health_changed.connect(_on_player_health_changed)
	backgroundmusic.play()
	await get_tree().create_timer(2.38).timeout
	pipebye.play()


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


func add_coin(amount: int = 1) -> void:
	if amount <= 0:
		return

	coins += amount
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
