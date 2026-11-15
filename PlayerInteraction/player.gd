extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var playermusic = $PlayerAudio
const SPEED = 300.0
const JUMP_VELOCITY = -300.0
const INTRO_ZOOM_MULTIPLIER = 3.0
const INTRO_ZOOM_DURATION = 2.0

var intro_waiting := true
var movement_enabled := false


func _ready() -> void:
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


func _physics_process(delta: float) -> void:
	if intro_waiting:
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if movement_enabled and Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		

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

		
	if not is_on_floor():
		if animated_sprite.animation != "jump":
			animated_sprite.play("jump")
	elif direction != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")
		
	move_and_slide()
	
	


func _on_coin_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.


func _on_coin_body_exited(_body: Node2D) -> void:
	pass # Replace with function body.
