extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export_range(0.0, 500.0, 1.0, "or_greater") var speed: float = 45.0
@export_range(0.0, 1000.0, 1.0, "or_greater") var detection_range: float = 50.0
@export var stopping_distance: float = 20.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.0

var player: CharacterBody2D
var attack_timer := 0.0


func _ready() -> void:
	animated_sprite.play("idle")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	attack_timer = maxf(attack_timer - delta, 0.0)

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if is_instance_valid(player):
		var distance_to_player := player.global_position.x - global_position.x
		if absf(distance_to_player) <= detection_range and absf(distance_to_player) > stopping_distance:
			var direction := signf(distance_to_player)
			velocity.x = direction * speed
			animated_sprite.flip_h = direction < 0
			if animated_sprite.animation != "run":
				animated_sprite.play("run")
		elif absf(distance_to_player) <= stopping_distance:
			velocity.x = move_toward(velocity.x, 0.0, speed)
			if attack_timer == 0.0 and player.has_method("take_damage"):
				player.call("take_damage", damage)
				attack_timer = attack_cooldown

			if animated_sprite.sprite_frames.has_animation("hit"):
				if animated_sprite.animation != "hit":
					animated_sprite.play("hit")
			elif animated_sprite.animation != "idle":
				animated_sprite.play("idle")
		else:
			velocity.x = 0.0
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")
	else:
		velocity.x = 0.0
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

	move_and_slide()
