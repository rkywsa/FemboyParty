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
var gamepad_jump_requested := false
var rifle_visual: Node2D
var rifle_sound: AudioStreamPlayer2D


func _ready() -> void:
	add_to_group("player")
	health = max_health
	z_index = -1
	animated_sprite.play("jump")
	_create_rifle_visual()
	_create_rifle_sound()

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


func _create_rifle_visual() -> void:
	# Small, axis-aligned color blocks keep the hand-built gun pixel-shaped.
	rifle_visual = Node2D.new()
	rifle_visual.name = "RifleVisual"
	rifle_visual.visible = false
	rifle_visual.z_index = 2
	add_child(rifle_visual)

	# Barrel, receiver, stock, grip, and pixel highlights; all dimensions are integers.
	_add_rifle_part(PackedVector2Array([
		Vector2(4, -2), Vector2(14, -2), Vector2(14, 0), Vector2(4, 0)
	]), Color("#77727a"))
	_add_rifle_part(PackedVector2Array([
		Vector2(-4, -3), Vector2(6, -3), Vector2(6, 1), Vector2(-4, 1)
	]), Color("#35323b"))
	_add_rifle_part(PackedVector2Array([
		Vector2(-7, -2), Vector2(-4, -2), Vector2(-4, 1), Vector2(-7, 1)
	]), Color("#514c55"))
	_add_rifle_part(PackedVector2Array([
		Vector2(0, 1), Vector2(3, 1), Vector2(2, 5), Vector2(0, 5)
	]), Color("#514c55"))
	_add_rifle_part(PackedVector2Array([
		Vector2(3, -3), Vector2(6, -3), Vector2(6, -2), Vector2(3, -2)
	]), Color("#aaa3ad"))
	_add_rifle_part(PackedVector2Array([
		Vector2(7, -1), Vector2(10, -1), Vector2(10, 0), Vector2(7, 0)
	]), Color("#aaa3ad"))


func _add_rifle_part(points: PackedVector2Array, part_color: Color) -> void:
	var part := Polygon2D.new()
	part.polygon = points
	part.color = part_color
	rifle_visual.add_child(part)


func _create_rifle_sound() -> void:
	rifle_sound = AudioStreamPlayer2D.new()
	rifle_sound.name = "RifleSound"
	rifle_sound.stream = load("res://assets/sounds/tap.wav") as AudioStream
	rifle_sound.volume_db = -4.0
	add_child(rifle_sound)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_A:
				gamepad_jump_requested = true
			JOY_BUTTON_RIGHT_SHOULDER:
				select_weapon("rifle" if current_weapon == "sword" else "sword")
			JOY_BUTTON_B:
				_use_current_weapon()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			select_weapon("sword")
		elif event.keycode == KEY_2:
			select_weapon("rifle")

	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		_use_current_weapon()


func select_weapon(weapon_name: String) -> void:
	if weapon_name not in ["sword", "rifle"]:
		push_warning("Unknown weapon selected: %s" % weapon_name)
		return
	if current_weapon == weapon_name:
		return

	current_weapon = weapon_name
	rifle_visual.visible = current_weapon == "rifle"
	weapon_changed.emit(current_weapon)


func _use_current_weapon() -> void:
	if not movement_enabled or intro_waiting:
		return
	if current_weapon == "sword":
		_play_attack()
	else:
		_shoot_rifle()


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


func die() -> void:
	if health <= 0:
		return

	health = 0
	movement_enabled = false
	velocity = Vector2.ZERO
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if intro_waiting:
		gamepad_jump_requested = false
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if movement_enabled and (Input.is_action_just_pressed("ui_accept") or gamepad_jump_requested) and is_on_floor():
		velocity.y = JUMP_VELOCITY
	gamepad_jump_requested = false

	var direction := 0.0
	if movement_enabled:
		direction = Input.get_axis("ui_left", "ui_right")

	if direction != 0.0:
		facing_direction = signf(direction)
		animated_sprite.flip_h = direction < 0.0

	if current_weapon == "rifle":
		rifle_visual.position = Vector2(3.0 * facing_direction, 1.0)
		rifle_visual.scale.x = facing_direction

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
	# Fire from the lowered gun's muzzle, so the yellow shot visibly exits its barrel.
	var muzzle := global_position + Vector2(17.0 * facing_direction, 1.0)
	var to := muzzle + Vector2(facing_direction * RIFLE_RANGE, 0.0)
	var query := PhysicsRayQueryParameters2D.create(muzzle, to)
	query.exclude = [self]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)

	var shot_end: Vector2 = to
	if not hit.is_empty():
		shot_end = hit["position"]
		var target: Object = hit["collider"]
		if target is Node and target.is_in_group("enemy") and target.has_method("take_weapon_damage"):
			target.call("take_weapon_damage", RIFLE_DAMAGE, global_position)

	if rifle_sound.stream != null:
		rifle_sound.play()
	_show_rifle_shot(muzzle, shot_end)


func _show_rifle_shot(from: Vector2, to: Vector2) -> void:
	var shot_line := Line2D.new()
	shot_line.width = 1.0
	shot_line.antialiased = false
	shot_line.default_color = Color("#ffe52b")
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
