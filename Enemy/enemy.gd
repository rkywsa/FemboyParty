extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var speed: float = 45.0
@export var stopping_distance: float = 20.0

var player: CharacterBody2D


func _ready() -> void:
	animated_sprite.play("idle")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if is_instance_valid(player):
		var distance_to_player := player.global_position.x - global_position.x
		if absf(distance_to_player) > stopping_distance:
			var direction := signf(distance_to_player)
			velocity.x = direction * speed
			animated_sprite.flip_h = direction < 0
			if animated_sprite.animation != "run":
				animated_sprite.play("run")
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed)
			if animated_sprite.sprite_frames.has_animation("hit"):
				if animated_sprite.animation != "hit":
					animated_sprite.play("hit")
			elif animated_sprite.animation != "idle":
				animated_sprite.play("idle")
	else:
		velocity.x = 0.0
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

	move_and_slide()
