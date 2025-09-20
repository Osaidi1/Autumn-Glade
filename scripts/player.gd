class_name Player
extends CharacterBody2D

const walkspeed = 40
const runspeed = 120
const JUMP_VELOCITY = -280.0
const friction = 100
const health = 100
var SPEED = 300.0
var stopping
var is_moving = false
var is_jumping = false
var is_crouching = false
var jump_available = true
var only_falling = false
var can_control = true
@export var coyote_time = 0.1
@onready var collision: CollisionShape2D = $Collision
@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyotetime: Timer = $"coyote time"
var croutchcshape = preload("res://collisions/croutchslide.tres")
var idlecshape = preload("res://collisions/idle.tres")

func healthset():
	pass

func _ready():
	collision.shape = idlecshape
	collision.position.y = 0
	visible = true

func walkorrun(SPEED):
	if Input.is_action_pressed("run"):
		SPEED = runspeed
	else:
		SPEED = walkspeed
	return SPEED

func jump():
	if Input.is_action_just_pressed("jump") and jump_available:
		is_jumping = true
		velocity.y = JUMP_VELOCITY 
		jump_available = false
	if Input.is_action_just_released("jump") and !jump_available:
		velocity.y*= 0.4

func facing(direction):
	if direction < 0:
		animator.flip_h = true
		collision.position.x = -5
	if direction > 0:
		animator.flip_h = false
		collision.position.x = 0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("crouch") and !is_jumping:
		is_crouching = true
	if event.is_action_released("crouch"):
		is_crouching = false
	crouch()

func crouch():
	if is_crouching:
		collision.shape = croutchcshape
		collision.position.y = 4.5
	elif !is_crouching:
		collision.shape = idlecshape
		collision.position.y = 0

func _physics_process(delta: float) -> void:
	if !can_control: 
		handle_death()
		return
	
	if is_on_floor():
		is_jumping = false
		only_falling = false
	
	var direction := Input.get_axis("left", "right")
	
	# Add the gravity.
	if not is_on_floor():
		if jump_available:
			if coyotetime.is_stopped():
				coyotetime.start(coyote_time)
			#get_tree().create_timer(coyote_time).timeout.connect(coyote_timeout)
		velocity += get_gravity() * delta
	else:
		jump_available = true
		coyotetime.stop()
	
	#Handle fall
	if not is_on_floor() and not Input.is_action_just_pressed("jump") and velocity.y > 0: 
		only_falling = true
	
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
	if is_crouching:
		animator.play("crouch")
	elif !is_crouching:
		if is_on_floor():
			if SPEED == runspeed and is_moving == true:
				animator.play("run")
			elif SPEED == walkspeed and is_moving == true:
				animator.play("walk")
			else:
				animator.play("idle")
		if !is_on_floor():
			if velocity.y < 0:
				animator.play("jump")
			else:
				animator.play("fall")

func coyote_timeout():
	jump_available = false

func handle_death():
	velocity.y = 300
	print("died")
	animator.play("die")
	await get_tree().create_timer(1.1).timeout
