extends Node2D

@onready var backgroundmusic = $backgroundmusic
@onready var pipebye = $pipebye
@onready var health_bar: TextureProgressBar = $HUD/HealthBar
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	player.health_changed.connect(_on_player_health_changed)
	backgroundmusic.play()
	await get_tree().create_timer(2.38).timeout
	pipebye.play()


func _on_player_health_changed(current_health: int, _maximum_health: int) -> void:
	health_bar.value = current_health
