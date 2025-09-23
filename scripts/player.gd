class_name Player
extends CharacterBody2D

@onready var animator: AnimatedSprite2D = $Animations
@onready var collision: CollisionShape2D = $Collision
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var coyote_timer: Timer = $coyote_timer
@onready var ladder_cast: RayCast2D = $LadderCheck


@export var Coyote_Time = 0.2
@export var Jump_Velocity = -210
@export var Walk_Speed = 45
@export var Run_Speed = 120
@export var Health = 100
@export var jump_buffer_timer = 0.1
@export var climb_speed = -200

const IDLE = preload("res://collisions/idle.tres")
const CROUTCHSLIDE = preload("res://collisions/croutchslide.tres")

var is_falling = false
var can_climb = false
var is_crouching = false
var is_climbing = false
var can_crouch = true
var can_attack = true
var jump_available = true
var is_attacking = false
var is_jumping = false
var speed = 45
const gravity = 9.8
var dir
var main_sm : LimboHSM

func _ready():
	initate_state_machine()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if !is_falling:
		if event.is_action_pressed("crouch") and can_crouch:
			main_sm.dispatch(&"go_crouch")
		if event.is_action_pressed("attack") and can_attack:
			main_sm.dispatch(&"go_attack")
		if !is_crouching and !is_attacking:
			if event.is_action_pressed("climb up") and can_climb:
				main_sm.dispatch(&"go_climb")
			if !is_climbing:
				if event.is_action_pressed("jump") and jump_available:
					main_sm.dispatch(&"go_jump")
					jump_available = false

func _physics_process(delta: float) -> void:
	#print(main_sm.get_active_state())
	
	#Check For Ladder
	var laddercollider = ladder_cast.get_collider()
	if laddercollider:
		can_climb = true
	else:
		can_climb = false
	
	#Change Variables
	if is_on_floor():
		jump_available = true
		can_attack = true
		coyote_timer.stop()
	if !is_on_floor():
		if jump_available:
			if coyote_timer.is_stopped():
				coyote_timer.start(Coyote_Time)
		can_attack = false
	
	if is_attacking:
		can_crouch = false
	if !is_attacking:
		can_crouch = true
	
	if is_crouching:
		jump_available = false
	if !is_crouching:
		jump_available = true
	
	if is_jumping:
		can_crouch = false
	elif !is_jumping:
		can_crouch = true
	
	
	#Change Speed
	if Input.is_action_pressed("run"):
		speed = Run_Speed
	else:
		speed = Walk_Speed
	
	#Handle Health
	health_bar.init_health(Health)
	
	# Get Direction
	dir = Input.get_action_strength("right") - Input.get_action_strength("left")
	#Move
	if dir:
		velocity.x = dir * speed
	else:
		velocity.x = move_toward(velocity.x, 0 , 2000 * delta)
			
	#Gravity
	if !Input.is_action_pressed("climb up"):
		velocity.y += gravity
	
	#Face Correct Direction
	facing_dir()
	
	if !is_attacking and !is_crouching:
		move_and_slide()

func Coyote_Timer() -> void:
	jump_available = false 

func facing_dir():
	if !is_attacking and !is_climbing:
		if dir < 0:
			animator.flip_h = true
			collision.position.x = -5
		if dir > 0:
			animator.flip_h = false
			collision.position.x = 0

func coyote_timeout():
	pass

func initate_state_machine():
	main_sm = LimboHSM.new()
	add_child(main_sm)
	
	var idle_state = LimboState.new().named("idle").call_on_enter(idle_start).call_on_update(idle_process)
	var walk_state = LimboState.new().named("walk").call_on_enter(walk_start).call_on_update(walk_process)
	var run_state = LimboState.new().named("run").call_on_enter(run_start).call_on_update(run_process)
	var jump_state = LimboState.new().named("jump").call_on_enter(jump_start).call_on_update(jump_process)
	var fall_state = LimboState.new().named("fall").call_on_enter(fall_start).call_on_update(fall_process)
	var attack_state = LimboState.new().named("attack").call_on_enter(attack_start).call_on_update(attack_process)
	var slide_state = LimboState.new().named("slide").call_on_enter(slide_start).call_on_update(slide_process)
	var crouch_state = LimboState.new().named("crouch").call_on_enter(crouch_start).call_on_update(crouch_process)
	var climb_state = LimboState.new().named("climb").call_on_enter(climb_start).call_on_update(climb_process)
	var heal_state = LimboState.new().named("heal").call_on_enter(heal_start).call_on_update(heal_process)
	var block_state = LimboState.new().named("block").call_on_enter(block_start).call_on_update(block_process)
	var die_state = LimboState.new().named("die").call_on_enter(die_start).call_on_update(die_process)
	
	main_sm.add_child(idle_state)
	main_sm.add_child(walk_state)
	main_sm.add_child(run_state)
	main_sm.add_child(jump_state)
	main_sm.add_child(fall_state)
	main_sm.add_child(attack_state)
	main_sm.add_child(slide_state)
	main_sm.add_child(crouch_state)
	main_sm.add_child(climb_state)
	main_sm.add_child(heal_state)
	main_sm.add_child(block_state)
	main_sm.add_child(die_state)
	
	main_sm.initial_state = idle_state
	
	main_sm.add_transition(main_sm.ANYSTATE, idle_state, &"state_ended")
	main_sm.add_transition(main_sm.ANYSTATE, walk_state, &"go_walk")
	main_sm.add_transition(main_sm.ANYSTATE, run_state, &"go_run")
	main_sm.add_transition(main_sm.ANYSTATE, jump_state, &"go_jump")
	main_sm.add_transition(main_sm.ANYSTATE, fall_state, &"go_fall")
	main_sm.add_transition(main_sm.ANYSTATE, attack_state, &"go_attack")
	main_sm.add_transition(main_sm.ANYSTATE, slide_state, &"go_slide")
	main_sm.add_transition(main_sm.ANYSTATE, crouch_state, &"go_crouch")
	main_sm.add_transition(main_sm.ANYSTATE, climb_state, &"go_climb")
	main_sm.add_transition(main_sm.ANYSTATE, heal_state, &"go_heal")
	main_sm.add_transition(main_sm.ANYSTATE, block_state, &"go_block")
	main_sm.add_transition(main_sm.ANYSTATE, die_state, &"go_die")
	
	main_sm.initialize(self)
	main_sm.set_active(true)

# IDLE

func idle_start():
	animator.play("idle")

func idle_process(_delta: float):
	if !is_falling:
		if velocity.y < 0 and !is_on_floor():
			main_sm.dispatch(&"go_fall")
		elif dir != 0:
			if Input.is_action_pressed("run"):
				main_sm.dispatch(&"go_run")
			else:
				main_sm.dispatch(&"go_walk")

# WALK

func walk_start():
	animator.play("walk")

func walk_process(_delta: float):
	if !is_falling:
		if velocity.y < 0 and !is_on_floor():
			main_sm.dispatch(&"go_fall")
		elif Input.is_action_pressed("run"):
			main_sm.dispatch(&"go_run")
		elif dir == 0:
			main_sm.dispatch(&"state_ended")

# RUN

func run_start():
	animator.play("run")

func run_process(_delta: float):
	if !is_falling:
		if velocity.y < 0 and !is_on_floor():
			main_sm.dispatch(&"go_fall")
		elif Input.is_action_just_released("run"):
			if dir != 0:
				main_sm.dispatch(&"go_walk")
			else:
				main_sm.dispatch(&"state_ended")
		elif dir == 0:
			main_sm.dispatch(&"state_ended")

# JUMP

func jump_start():
	animator.play("jump")
	is_jumping = true
	jump_available = false
	velocity.y = Jump_Velocity

func jump_process(_delta: float):
	if Input.is_action_just_released("jump") and !jump_available:
		velocity.y *= 0.4
	if is_on_floor():
		is_jumping = false
		if Input.is_action_pressed("run") and dir != 0:
			main_sm.dispatch(&"go_run")
		elif dir != 0:
			main_sm.dispatch(&"go_walk")
		else:
			main_sm.dispatch(&"state_ended")

# FALL

func fall_start():
	animator.play("fall")
	is_falling = true

func fall_process(_delta: float):
	if is_on_floor():
		is_falling = false
		if Input.is_action_pressed("run") and dir != 0:
			main_sm.dispatch(&"go_run")
		elif dir != 0:
			main_sm.dispatch(&"go_walk")
		else:
			main_sm.dispatch(&"state_ended")

# ATTACK

func attack_start():
	is_attacking = true
	animator.play("attack 1")

func attack_process(_delta: float):
	if animator.is_playing(): return
	if Input.is_action_pressed("run") and dir != 0:
		is_attacking = false
		main_sm.dispatch(&"go_run")
	elif dir != 0:
		is_attacking = false
		main_sm.dispatch(&"go_walk")
	else:
		is_attacking = false
		main_sm.dispatch(&"state_ended")

# SLIDE

func slide_start():
	pass

func slide_process(_delta: float):
	pass

# CROUCH

func crouch_start():
	if !is_on_floor(): return
	is_crouching = true
	collision.shape = CROUTCHSLIDE
	collision.position.y += 4.5
	animator.play("crouch")

func crouch_process(_delta: float):
	if Input.is_action_pressed("crouch"):
		return
	if Input.is_action_just_released("crouch"):
		collision.shape = IDLE
		collision.position.y = 0
	if !is_falling:
		if Input.is_action_pressed("run") and dir != 0:
			is_crouching = false
			main_sm.dispatch(&"go_run")
		elif dir != 0:
			is_crouching = false
			main_sm.dispatch(&"go_walk")
		else:
			is_crouching = false
			main_sm.dispatch(&"state_ended")

# CLIMB

func climb_start():
	animator.play("climb up")
	is_climbing = true

func climb_process(delta: float):
	var updowndir = Input.get_axis("climb up", "climb down")
	if is_climbing and is_on_floor():
		is_climbing = false
	if is_climbing:
		velocity.y = updowndir * climb_speed * delta
		move_and_slide()
	if Input.is_action_just_released("climb up") or Input.is_action_just_released("climb down") or !can_climb:
		if velocity.y > 0 and !is_on_floor():
			main_sm.dispatch(&"go_fall")
			is_climbing = false
		elif Input.is_action_just_released("run"):
			if dir != 0:
				main_sm.dispatch(&"go_walk")
				is_climbing = false
			else:
				main_sm.dispatch(&"state_ended")
				is_climbing = false
		elif dir == 0:
			main_sm.dispatch(&"state_ended")
			is_climbing = false

# HEAL

func heal_start():
	pass

func heal_process(_delta: float):
	pass

# BLOCK

func block_start():
	pass

func block_process(_delta: float):
	pass

# DIE

func die_start():
	pass

func die_process(_delta: float):
	pass

# END
