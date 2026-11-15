extends Area2D

@onready var coin_sound: AudioStreamPlayer2D = $CoinSound
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var collected := false


func _ready() -> void:
	animated_sprite.play("coin")


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return

	collected = true
	monitoring = false
	visible = false
	collision_shape.set_deferred("disabled", true)

	var level := get_tree().current_scene
	if level != null and level.has_method("add_coin"):
		level.call("add_coin", 1)

	# Keep the pickup sound alive after this coin node is removed.
	if is_instance_valid(coin_sound) and level != null:
		coin_sound.reparent(level)
		coin_sound.finished.connect(coin_sound.queue_free)
		coin_sound.play()

	queue_free()
