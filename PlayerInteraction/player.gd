extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)
signal weapon_changed(weapon_name: String)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var playermusic: AudioStreamPlayer2D = $PlayerAudio

@export var max_health: int = 100

const SPEED: float = 100.0
const JUMP_VELOCITY: float = -300.0
const INTRO_ZOOM_MULTIPLIER: float = 3.0
const INTRO_ZOOM_DURATION: float = 2.0
const ATTACK_COOLDOWN: float = 1.0
const SWORD_RANGE: float = 42.0
const RIFLE_RANGE: float = 600.0
const SWORD_DAMAGE: int = 3
const RIFLE_DAMAGE: int = 2
const KNOCKBACK_SPEED: float = 100.0
const KNOCKBACK_DURATION: float = 0.1

var intro_waiting := true
var movement_enabled := false
var attacking := false
var hurt_animation_playing := false
var attack_on_cooldown := false
var health: int
var facing_direction: float = 1.0
var current_weapon: String = "sword"
var knockback_direction: float = 0.0
var knockback_time: float = 0.0


func _ready() -> void:
	add_to_group("player")
	health = max_health
	z_index = -1
	animated_sprite.play("jump")

	var normal_zoom := camera.zoom
	camera.zoom = normal_zoom * INTRO_ZOOM_MULTIPLIER

	var tween := create_tween()
	tween.tween_property(camera, "zoom", normal_zoom, INTRO_ZOOM_DURATION) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	await tween.finished

	intro_waiting = false
	while not is_on_floor():
		await get_tree().physics_frame

	z_index = 1
	movement_enabled = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			select_weapon("sword")
		elif event.keycode == KEY_2:
			select_weapon("rifle")

	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		if not movement_enabled or intro_waiting:
			return
		if current_weapon == "sword":
			_play_attack()
		else:
			_shoot_rifle()


func select_weapon(weapon_name: String) -> void:
	if weapon_name not in ["sword", "rifle"]:
		push_warning("Unknown weapon selected: %s" % weapon_name)
		return
	if current_weapon == weapon_name:
		return

	current_weapon = weapon_name
	weapon_changed.emit(current_weapon)


func take_damage(amount: int, source_position: Vector2) -> void:
	if not movement_enabled or amount <= 0 or health <= 0:
		return

	knockback_direction = signf(global_position.x - source_position.x)
	if knockback_direction == 0.0:
		knockback_direction = -facing_direction
	knockback_time = KNOCKBACK_DURATION
	velocity.y = -sqrt(4.0 * maxf(get_gravity().y, 0.0))
	health = maxi(health - amount, 0)
	_play_hurt()
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if intro_waiting:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if movement_enabled and Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := 0.0
	if movement_enabled:
		direction = Input.get_axis("ui_left", "ui_right")

	if direction != 0.0:
		facing_direction = signf(direction)
		animated_sprite.flip_h = direction < 0.0

	if knockback_time > 0.0:
		knockback_time = maxf(knockback_time - delta, 0.0)
		velocity.x = knockback_direction * KNOCKBACK_SPEED
	elif direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	if direction != 0.0 and is_on_floor():
		if not playermusic.playing:
			playermusic.play()
	elif playermusic.playing:
		playermusic.stop()

	if not attacking and not hurt_animation_playing:
		if not is_on_floor():
			if animated_sprite.animation != "jump":
				animated_sprite.play("jump")
		elif direction != 0.0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")

	move_and_slide()


func _play_attack() -> void:
	if attacking or hurt_animation_playing or attack_on_cooldown:
		return

	attacking = true
	attack_on_cooldown = true
	animated_sprite.play("hit")
	_hit_enemy_with_sword()

	var attack_duration: float = float(animated_sprite.sprite_frames.get_frame_count("hit")) \
			/ animated_sprite.sprite_frames.get_animation_speed("hit")
	await get_tree().create_timer(attack_duration).timeout
	attacking = false
	var remaining_cooldown := maxf(ATTACK_COOLDOWN - attack_duration, 0.0)
	if remaining_cooldown > 0.0:
		await get_tree().create_timer(remaining_cooldown).timeout
	attack_on_cooldown = false


func _hit_enemy_with_sword() -> void:
	var target: Node2D = null
	var closest_distance := SWORD_RANGE + 1.0

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		var offset: Vector2 = enemy.global_position - global_position
		var horizontal_distance := offset.x * facing_direction
		if horizontal_distance < 0.0 or horizontal_distance > SWORD_RANGE:
			continue
		if absf(offset.y) > 48.0:
			continue
		if horizontal_distance < closest_distance:
			closest_distance = horizontal_distance
			target = enemy

	if is_instance_valid(target) and target.has_method("take_weapon_damage"):
		target.call("take_weapon_damage", SWORD_DAMAGE, global_position)


func _shoot_rifle() -> void:
	var from := global_position + Vector2(0.0, 4.0)
	var to := from + Vector2(facing_direction * RIFLE_RANGE, 0.0)
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)

	var shot_end: Vector2 = to
	if not hit.is_empty():
		shot_end = hit["position"]
		var target: Object = hit["collider"]
		if target is Node and target.is_in_group("enemy") and target.has_method("take_weapon_damage"):
			target.call("take_weapon_damage", RIFLE_DAMAGE, global_position)

	_show_rifle_shot(from, shot_end)


func _show_rifle_shot(from: Vector2, to: Vector2) -> void:
	var shot_line := Line2D.new()
	shot_line.width = 2.0
	shot_line.default_color = Color(1.0, 0.85, 0.25, 1.0)
	shot_line.points = PackedVector2Array([to_local(from), to_local(to)])
	add_child(shot_line)
	var tween := create_tween()
	tween.tween_property(shot_line, "modulate:a", 0.0, 0.12)
	tween.finished.connect(shot_line.queue_free)


func _play_hurt() -> void:
	if attacking:
		attacking = false
	hurt_animation_playing = true
	animated_sprite.play("hurt")
	var hurt_duration: float = float(animated_sprite.sprite_frames.get_frame_count("hurt")) \
			/ animated_sprite.sprite_frames.get_animation_speed("hurt")
	await get_tree().create_timer(hurt_duration).timeout
	hurt_animation_playing = false
