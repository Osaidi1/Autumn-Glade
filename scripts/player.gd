class_name Player
extends CharacterBody2D

const walkspeed = 40
const runspeed = 120
const JUMP_VELOCITY = -280.0
const friction = 100
const maxhealth = 100
const minhealth = 0
var currenthealth : int = 100
var SPEED = 300.0
var climb_speed = 200
var is_dying = false
var is_moving = false
var is_jumping = false
var is_crouching = false
var jump_available = true
var only_falling = false
var can_control = true
var wants_to_climb = false
var can_climb = false
var go_climb = false
var is_climbing = false
var vertical_dir
@export var coyote_time = 0.1
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var collision: CollisionShape2D = $Collision
@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyotetime: Timer = $"coyote time"
var croutchcshape = preload("res://collisions/croutchslide.tres")
var idlecshape = preload("res://collisions/idle.tres")

func _ready():
	health_bar.visible = true
	currenthealth = maxhealth
	collision.shape = idlecshape
	collision.position.y = 0
	visible = true
	health_bar.init_health(currenthealth)
	is_dying = false

func climb_vars():
	if Input.is_action_pressed("climb up") or Input.is_action_pressed("climb down"):
		wants_to_climb = true
	else:
		wants_to_climb = false

func climb():
	if wants_to_climb and can_climb:
		animator.play("climb")
		go_climb = true
	if !wants_to_climb and !can_climb:
		is_climbing = false
		go_climb = false

func healthset():
	if currenthealth > maxhealth:
		currenthealth = maxhealth
	if currenthealth < minhealth:
		currenthealth = minhealth

func change_health(change):
	currenthealth += change
	if currenthealth <= 0:
		currenthealth = 0
		is_dying = true
		can_control = false
		handle_death()
	
	health_bar._set_health(currenthealth)

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
	if event.is_action_pressed("damage_temp"):
		change_health(-30)

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
	
	#Set Climb Vars
	climb_vars()
	
	#Handle Health Set
	healthset()
	
	if is_on_floor():
		is_jumping = false
		only_falling = false
	
	var vertical_dir = Input.get_axis("climb up", "climb down")
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
	
	#Handle Climb Itself
	climb()
	
	if go_climb == true:
		velocity.y = climb_speed * delta * vertical_dir
		is_climbing = true
	if is_on_floor():
		is_climbing = false
	
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
	health_bar.visible = false
	animator.play("die")
	await get_tree().create_timer(1.1).timeout
	if get_tree():
		get_tree().reload_current_scene()
	health_bar.visible = false

func _on_laderchecker_body_entered(body: Node2D) -> void:
	can_climb = true

func _on_laderchecker_body_exited(body: Node2D) -> void:
	can_climb = false
