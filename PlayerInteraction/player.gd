extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)

@onready var animated_sprite = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var playermusic = $PlayerAudio

@export var max_health: int = 100

const SPEED = 100.0
const JUMP_VELOCITY = -300.0
const INTRO_ZOOM_MULTIPLIER = 3.0
const INTRO_ZOOM_DURATION = 2.0
const ATTACK_COOLDOWN = 0.3

var intro_waiting := true
var movement_enabled := false
var attacking := false
var hurt_animation_playing := false
var attack_on_cooldown := false
var health: int


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


func take_damage(amount: int) -> void:
	if not movement_enabled or amount <= 0 or health <= 0:
		return

	health = maxi(health - amount, 0)
	_play_hurt()
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if intro_waiting:
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if movement_enabled and Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if movement_enabled and Input.is_action_just_pressed("player_attack") \
			and not attacking and not hurt_animation_playing and not attack_on_cooldown:
		_play_attack()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := 0.0
	if movement_enabled:
		direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED

	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	if direction != 0 and is_on_floor():
		if not playermusic.playing:
			playermusic.play()
	elif playermusic.playing:
		playermusic.stop()

		
	if not attacking and not hurt_animation_playing:
		if not is_on_floor():
			if animated_sprite.animation != "jump":
				animated_sprite.play("jump")
		elif direction != 0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")
		
	move_and_slide()


func _play_attack() -> void:
	attacking = true
	attack_on_cooldown = true
	animated_sprite.play("hit")
	var attack_duration: float = float(animated_sprite.sprite_frames.get_frame_count("hit")) \
			/ animated_sprite.sprite_frames.get_animation_speed("hit")
	await get_tree().create_timer(attack_duration).timeout
	attacking = false
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	attack_on_cooldown = false


func _play_hurt() -> void:
	if attacking:
		attacking = false
	hurt_animation_playing = true
	animated_sprite.play("hurt")
	var hurt_duration: float = float(animated_sprite.sprite_frames.get_frame_count("hurt")) \
			/ animated_sprite.sprite_frames.get_animation_speed("hurt")
	await get_tree().create_timer(hurt_duration).timeout
	hurt_animation_playing = false
	
	


func _on_coin_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.


func _on_coin_body_exited(_body: Node2D) -> void:
	pass # Replace with function body.
