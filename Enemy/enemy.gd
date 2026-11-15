extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export_range(0.0, 500.0, 1.0, "or_greater") var speed: float = 45.0
@export_range(0.0, 1000.0, 1.0, "or_greater") var detection_range: float = 50.0
@export var stopping_distance: float = 26.0
@export var attack_vertical_range: float = 64.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.0
@export var max_weapon_health: int = 6

const KNOCKBACK_SPEED: float = 100.0
const KNOCKBACK_DURATION: float = 0.1

var player: CharacterBody2D
var attack_timer := 0.0
var weapon_health: int
var defeated := false
var knockback_direction: float = 0.0
var knockback_time: float = 0.0


func _ready() -> void:
	add_to_group("enemy")
	weapon_health = max_weapon_health
	animated_sprite.play("idle")


func take_weapon_damage(amount: int, source_position: Vector2) -> void:
	if defeated or amount <= 0:
		return

	knockback_direction = signf(global_position.x - source_position.x)
	if knockback_direction == 0.0:
		knockback_direction = -1.0 if animated_sprite.flip_h else 1.0
	knockback_time = KNOCKBACK_DURATION
	velocity.y = -sqrt(4.0 * maxf(get_gravity().y, 0.0))
	weapon_health = maxi(weapon_health - amount, 0)
	if weapon_health == 0:
		defeated = true
		velocity = Vector2.ZERO
		collision_shape.set_deferred("disabled", true)
		animated_sprite.play("die")
		await get_tree().create_timer(1.5).timeout
		queue_free()


func _physics_process(delta: float) -> void:
	if defeated:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	attack_timer = maxf(attack_timer - delta, 0.0)

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if knockback_time > 0.0:
		velocity.x = knockback_direction * KNOCKBACK_SPEED
		knockback_time = maxf(knockback_time - delta, 0.0)
		if animated_sprite.animation != "hit":
			animated_sprite.play("hit")
	elif is_instance_valid(player):
		var offset_to_player := player.global_position - global_position
		var horizontal_distance := absf(offset_to_player.x)
		var vertical_distance := absf(offset_to_player.y)
		if horizontal_distance <= stopping_distance and vertical_distance <= attack_vertical_range:
			velocity.x = move_toward(velocity.x, 0.0, speed)
			if attack_timer == 0.0 and player.has_method("take_damage"):
				player.call("take_damage", damage, global_position)
				attack_timer = attack_cooldown

			if animated_sprite.animation != "hit":
				animated_sprite.play("hit")
		elif offset_to_player.length() <= detection_range and horizontal_distance > stopping_distance:
			var direction := signf(offset_to_player.x)
			velocity.x = direction * speed
			if direction != 0.0:
				animated_sprite.flip_h = direction < 0
			if animated_sprite.animation != "run":
				animated_sprite.play("run")
		else:
			velocity.x = 0.0
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")
	else:
		velocity.x = 0.0
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

	move_and_slide()
