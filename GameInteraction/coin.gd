extends Node2D

@onready var coin_sound: AudioStreamPlayer2D = $CoinSound
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var collected := false


func _ready() -> void:
	animated_sprite.play("coin")


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return

	collected = true
	set_deferred("monitoring", false)

	# The level root owns the counter; keep the coin independent of the HUD.
	var level: Node = get_tree().current_scene
	if level != null and level.has_method("add_coin"):
		level.call("add_coin", 1)
	else:
		push_warning("Coin collected, but the current scene has no add_coin() method.")

	# Detach the sound so it can finish after this coin is removed.
	if is_instance_valid(coin_sound) and level != null:
		coin_sound.reparent(level)
		coin_sound.finished.connect(coin_sound.queue_free)
		coin_sound.play()

@onready var backgroundmusic: AudioStreamPlayer2D = $backgroundmusic
@onready var pipebye: AudioStreamPlayer2D = $pipebye
@onready var health_bar: TextureProgressBar = $HUD/HealthBar
@onready var player: CharacterBody2D = $Player
@onready var game_over: Control = $GameOverLayer/GameOver
@onready var restart_button: Button = $GameOverLayer/GameOver/CenterContainer/Menu/RestartButton
@onready var coin_label: Label = $HUD/CoinsLabel

var coins: int = 0


func _ready2() -> void:
	coin_label.text = "Coins: %d" % coins
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	player.health_changed.connect(_on_player_health_changed)
	backgroundmusic.play()
	await get_tree().create_timer(2.38).timeout
	pipebye.play()


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
