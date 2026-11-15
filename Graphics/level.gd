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

@onready var coinsound: AudioStreamPlayer2D = $CoinSound


func _readyy():
	$AnimatedSprite2D.play("coin")


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return


	# Dodaj monetę do licznika w skrypcie poziomu.
	var level := get_tree().current_scene
	if level != null and level.has_method("add_coin"):
		level.add_coin()
	else:
		push_warning("Nie znaleziono metody add_coin() w aktualnym poziomie.")

	set_deferred("monitoring", false)

	coinsound.reparent(get_tree().current_scene)
	coinsound.finished.connect(coinsound.queue_free)
	coinsound.play()

	queue_free()
