extends Node2D

@onready var backgroundmusic = $backgroundmusic
@onready var pipebye = $pipebye
@onready var health_bar: TextureProgressBar = $HUD/HealthBar
@onready var player: CharacterBody2D = $Player
@onready var game_over: Control = $GameOverLayer/GameOver
@onready var restart_button: Button = $GameOverLayer/GameOver/CenterContainer/Menu/RestartButton


func _ready() -> void:
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	player.health_changed.connect(_on_player_health_changed)
	backgroundmusic.play()
	await get_tree().create_timer(2.38).timeout
	pipebye.play()


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
