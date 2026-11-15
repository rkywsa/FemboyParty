extends Area2D

@onready var coinsound: AudioStreamPlayer2D = $CoinSound


func _ready() -> void:
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
