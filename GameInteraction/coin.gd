extends Area2D

@onready var coinsound = $CoinSound


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return

	set_deferred("monitoring", false)

	coinsound.reparent(get_tree().current_scene)
	coinsound.finished.connect(coinsound.queue_free)
	coinsound.play()

	queue_free()
