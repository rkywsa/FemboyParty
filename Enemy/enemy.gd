extends CharacterBody2D

signal enemy_defeated

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export_range(0.0, 500.0, 1.0, "or_greater") var speed: float = 45.0
@export_range(0.0, 1000.0, 1.0, "or_greater") var detection_range: float = 50.0
@export var stopping_distance: float = 18.0
@export var attack_vertical_range: float = 24.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.0
@export var max_weapon_health: int = 6

const KNOCKBACK_SPEED: float = 100.0
const KNOCKBACK_DURATION: float = 0.1

var player: CharacterBody2D
var attack_timer := 0.0
var weapon_health: int
var defeated := false
var has_seen_player := false
var attack_in_progress := false
var attack_hit_applied := false
var knockback_direction: float = 0.0
var knockback_time: float = 0.0


func _ready() -> void:
	add_to_group("enemy")
	weapon_health = max_weapon_health
	animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
	animated_sprite.frame_changed.connect(_on_animated_sprite_frame_changed)
	animated_sprite.play("idle")


func take_weapon_damage(amount: int, source_position: Vector2) -> void:
	if defeated or amount <= 0:
		return

	attack_in_progress = false
	knockback_direction = signf(global_position.x - source_position.x)
	if knockback_direction == 0.0:
		knockback_direction = -1.0 if animated_sprite.flip_h else 1.0
	knockback_time = KNOCKBACK_DURATION
	velocity.y = -sqrt(4.0 * maxf(get_gravity().y, 0.0))
	weapon_health = maxi(weapon_health - amount, 0)
	if weapon_health == 0:
		defeated = true
		enemy_defeated.emit()
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
		if not has_seen_player and offset_to_player.length() <= detection_range:
			has_seen_player = true

		if has_seen_player and _is_player_in_attack_range():
			velocity.x = move_toward(velocity.x, 0.0, speed)
			if offset_to_player.x != 0.0:
				animated_sprite.flip_h = offset_to_player.x < 0.0
			if not attack_in_progress and attack_timer == 0.0:
				attack_in_progress = true
				attack_hit_applied = false
				attack_timer = attack_cooldown
				animated_sprite.stop()
				animated_sprite.play("hit", 1.2)
			elif not attack_in_progress and animated_sprite.animation != "idle":
				animated_sprite.play("idle")
		elif has_seen_player:
			var direction := signf(offset_to_player.x)
			velocity.x = direction * speed
			if direction != 0.0:
				animated_sprite.flip_h = direction < 0
			if not attack_in_progress and animated_sprite.animation != "run":
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


func _on_animated_sprite_animation_finished() -> void:
	if not attack_in_progress or animated_sprite.animation != "hit":
		return

	attack_in_progress = false

func _on_animated_sprite_frame_changed() -> void:
	if not attack_in_progress or attack_hit_applied or animated_sprite.animation != "hit":
		return

	var hit_frame := animated_sprite.sprite_frames.get_frame_count("hit") - 2
	if animated_sprite.frame != hit_frame:
		return

	attack_hit_applied = true
	if not is_instance_valid(player) or not player.has_method("take_damage"):
		return

	if not _is_player_in_attack_range():
		return

	var direction_to_player := signf(player.global_position.x - global_position.x)
	if direction_to_player != 0.0:
		animated_sprite.flip_h = direction_to_player < 0.0
	player.call("take_damage", damage, global_position)


func _is_player_in_attack_range() -> bool:
	if not is_instance_valid(player):
		return false

	var offset_to_player := player.global_position - global_position
	return absf(offset_to_player.x) <= stopping_distance and absf(offset_to_player.y) <= attack_vertical_range
