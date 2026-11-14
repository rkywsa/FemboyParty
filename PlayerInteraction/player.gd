extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var playermusic = $PlayerMusic

const SPEED = 300.0
const JUMP_VELOCITY = -300.0
const INTRO_ZOOM_MULTIPLIER = 3.0
const INTRO_ZOOM_DURATION = 1.0


func _ready() -> void:
	var normal_zoom := camera.zoom
	camera.zoom = normal_zoom * INTRO_ZOOM_MULTIPLIER

	var tween := create_tween()
	tween.tween_property(camera, "zoom", normal_zoom, INTRO_ZOOM_DURATION) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED

	if direction > 0:
		animated_sprite.flip_h = false
		playermusic.play()
	elif direction < 0:
		animated_sprite.flip_h = true
		playermusic.play()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if not is_on_floor():
		if animated_sprite.animation != "jump":
			animated_sprite.play("jump")
	elif direction != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")
		
	print(animated_sprite.animation)
	move_and_slide()
	
	


func _on_coin_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.


func _on_coin_body_exited(_body: Node2D) -> void:
	pass # Replace with function body.
