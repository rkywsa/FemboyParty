extends Area2D

const SPEED: float = 260.0
const GRAVITY: float = 40.0
const LIFETIME: float = 4.0

var velocity: Vector2 = Vector2.ZERO
var damage: int = 0
var source_position: Vector2 = Vector2.ZERO
var shooter: Node
var life_remaining: float = LIFETIME


func launch(direction: float, arrow_damage: int, firing_player: Node2D) -> void:
	velocity = Vector2(direction * SPEED, -8.0)
	damage = arrow_damage
	shooter = firing_player
	source_position = firing_player.global_position
	rotation = 0.0 if direction >= 0.0 else PI


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	velocity.y += GRAVITY * delta
	life_remaining -= delta
	if life_remaining <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if is_instance_valid(shooter) and shooter.has_method("damage_enemy"):
			shooter.call("damage_enemy", body, damage)
		elif body.has_method("take_weapon_damage"):
			body.call("take_weapon_damage", damage, source_position)
		queue_free()
	elif not body.is_in_group("player"):
		queue_free()
