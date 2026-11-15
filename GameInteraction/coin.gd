extends Area2D

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

	queue_free()
