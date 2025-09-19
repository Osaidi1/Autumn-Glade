extends CharacterBody2D

const walk_speed = 50
const run_speed = 200
var SPEED = 300.0
var JUMP_VELOCITY = -280.0
var is_crouching = false
var is_sliding = false
var is_healing = false
var is_climbing = false
var is_attacking = false
var is_dying = false
var is_jumping = false
@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $Collision
var idlecshape = preload("res://collisions/idle.tres")
var crouchslidecshape = preload("res://collisions/croutchslide.tres")

func _ready() -> void:
	collision.shape = idlecshape

func change_speed():
	if Input.is_action_pressed("run"):
		SPEED = run_speed
	else:
		SPEED = walk_speed

func change_direction(direction):
	if direction < 0:
		animator.flip_h = true
	elif direction > 0:
		animator.flip_h = false
	
func handle_crouch():
	if Input.is_action_pressed("crouch"):
		is_crouching = true
		collision.shape = crouchslidecshape
		collision.position.y = 4.5
	elif Input.is_action_just_released("crouch"):
		is_crouching = false
		collision.shape = idlecshape
		collision.position.y = 0
	
func handle_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animator.play("jump")
	
func play_animations(direction):
	if is_on_floor():
		if is_crouching:
			animator.play("crouch on")
			animator.play("crouch")
			if Input.is_action_just_released("crouch"):
				animator.play("crouch off")
		else:
			if direction == 0:
				animator.play("idle")
				
			else:
				if Input.is_action_pressed("run"):
					animator.play("run")
				else:
					animator.play("walk")
	
func _physics_process(delta: float) -> void:
	
	#Change Direction
	var direction = Input.get_axis("left", "right")
	
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	#Handle Speed Change
	change_speed()
		
	#Handle Left Right Changes
	if !is_dying:
		if !is_attacking:
			if !is_climbing:
				if !is_sliding:
					change_direction(direction)
	
	#Handle Crouch
	if !is_dying:
		if !is_attacking:
			if !is_climbing:
				if !is_sliding:
					handle_crouch()
	
	#Handle Jump
	if !is_dying:
		if !is_attacking:
			if !is_climbing:
				if !is_sliding:
					if !is_crouching:
						handle_jump()
	
	#handle the movement/deceleration.
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 4 * delta)
		
	play_animations(direction)
	
	if !is_crouching:
		move_and_slide()
