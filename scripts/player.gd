extends CharacterBody2D

const walkspeed = 45
const runspeed = 150
const JUMP_VELOCITY = -280.0
const friction = 100
var SPEED = 300.0
var stopping
var is_moving = false
var is_jumping = false
var is_crouching = false
@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
@onready var crouch_on_wait: Timer = $AnimatedSprite2D/crouch_on_wait
@onready var crouch_off_wait: Timer = $AnimatedSprite2D/crouch_off_wait

func walkorrun(SPEED):
	if Input.is_action_pressed("run"):
		SPEED = runspeed
		
	else:
		SPEED = walkspeed
		
	return SPEED

func jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		is_jumping = true
		velocity.y = JUMP_VELOCITY 

func facing(direction):
	if direction < 0:
		animator.flip_h = true
	if direction > 0:
		animator.flip_h = false

func _physics_process(delta: float) -> void:
	if is_on_floor():
		is_jumping = false
	
	var direction := Input.get_axis("left", "right")
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	#Handle Directions
	facing(direction)
	
	#Handle Run or Walk
	SPEED = walkorrun(SPEED)
	
	#Handle Jump
	jump()
	
	# Get the input direction and handle the movement/deceleration.
	if direction:
		velocity.x = direction * SPEED
		is_moving = true
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta * 4)
		is_moving = false
		
	#Handle Anims
	play_run_walk_idle_jump_anims()
		
	if !is_crouching:
		move_and_slide()

func play_run_walk_idle_jump_anims():
	if !is_crouching:
		if is_on_floor():
			if SPEED == runspeed and is_moving == true:
				animator.play("run")
			elif SPEED == walkspeed and is_moving == true:
				animator.play("walk")
			else:
				animator.play("idle")
		else:
			if is_jumping:
				animator.play("jump")
