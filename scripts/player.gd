class_name Player
extends CharacterBody2D

@onready var animator: AnimatedSprite2D = $Animations
@onready var collision: CollisionShape2D = $Collision
@onready var health_bar: TextureProgressBar = $"Game Screen/HealthBar"
@onready var how_many_bottles: Label = $"Game Screen/Label"
@onready var attack_cooldown: Timer = $"Attack Cooldown"
@onready var combo_timer: Timer = $"Attack Combo"

@export var Jump_Velocity = -210
@export var Walk_Speed = 45
@export var Run_Speed = 120
@export var climb_speed = -50
@export var currenthealth = 100

const IDLE = preload("res://collisions/idle.tres")
const CROUTCH = preload("res://collisions/croutch.tres")

var can_climb = false
var can_control = true
var can_crouch = true
var can_attack = true
var is_blocking = false
var is_climbing = false
var is_healing = false
var is_falling = false
var is_crouching = false
var is_attacking = false
var is_jumping = false
var is_reloading = false
var combo_state : int = 0

const gravity = 9.8
var dir
var main_sm : LimboHSM
var speed = 45

func _ready():
	initate_state_machine()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	HealthBottles.health_bottles = 0
	collision.shape = IDLE
	collision.position.x = 0 
	collision.position.y = 0 
	is_reloading = false

func _unhandled_input(event):
	if !can_control: return
	if event.is_action_pressed("damage_temp"):
		currenthealth -= 30
	if event.is_action_pressed("slide") and !is_attacking and is_on_floor() and !is_crouching and !is_falling and !is_jumping and !is_healing:
		main_sm.dispatch(&"go_slide")
	if event.is_action_pressed("heal") and !is_attacking and is_on_floor() and !is_crouching and !is_falling and !is_jumping and HealthBottles.health_bottles > 0 and currenthealth < 100:
		main_sm.dispatch(&"go_heal")
	if event.is_action_pressed("crouch") and is_on_floor() and !is_jumping and !is_attacking and !is_falling and !is_healing:
		main_sm.dispatch(&"go_crouch")
	if event.is_action_pressed("attack") and can_attack and is_on_floor() and !is_jumping and !is_falling and !is_healing:
		main_sm.dispatch(&"go_attack")
	if event.is_action_pressed("block") and is_on_floor() and !is_jumping and !is_falling and !is_healing and !is_attacking and !is_crouching:
		main_sm.dispatch(&"go_block")
	if event.is_action_pressed("jump") and is_on_floor() and !is_attacking and !is_crouching and !is_falling and !is_healing:
			main_sm.dispatch(&"go_jump")

func _physics_process(delta: float) -> void:
	if !can_control: 
		main_sm.dispatch(&"go_die")
		return

	how_many_bottles.text = str(HealthBottles.health_bottles)
	
	print(main_sm.get_active_state())
	
	if currenthealth < 0:
		can_control = false
		main_sm.dispatch(&"go_die")
	
	#Change Variables
	if is_on_floor() and attack_cooldown.is_stopped():
		can_attack = true
	if !is_on_floor() and !attack_cooldown.is_stopped():
		can_attack = false
	
	#Handle Fall
	if velocity.y > 0 and !is_on_floor():
		main_sm.dispatch(&"go_fall")
	
	#Change Speed
	if Input.is_action_pressed("run"):
		speed = Run_Speed
	else:
		speed = Walk_Speed
	
	#Handle Health Bar and Health
	if currenthealth >= 100:
		currenthealth = 100
	if currenthealth <= 0:
		currenthealth = 0
	health_bar.change_health(currenthealth)
	
	# Get Direction
	dir = Input.get_action_strength("right") - Input.get_action_strength("left")
	#Move
	if dir:
		velocity.x = dir * speed
	else:
		velocity.x = move_toward(velocity.x, 0 , 2000 * delta)
			
	#Gravity
	velocity.y += gravity
	
	#Face Correct Direction
	facing_dir()
	
	if !is_attacking and !is_crouching and !is_healing and !is_blocking:
		move_and_slide()

func _on_attack_combo_timeout() -> void:
	combo_state = 0

func cooldown_finish() -> void:
	can_attack = true

func facing_dir():
	if !can_control: return
	if !is_attacking and !is_blocking:
		if dir < 0:
			animator.flip_h = true
			collision.position.x = -5
		if dir > 0:
			animator.flip_h = false
			collision.position.x = 0

func initate_state_machine():
	main_sm = LimboHSM.new()
	add_child(main_sm)
	
	var idle_state = LimboState.new().named("idle").call_on_enter(idle_start).call_on_update(idle_process)
	var walk_state = LimboState.new().named("walk").call_on_enter(walk_start).call_on_update(walk_process)
	var run_state = LimboState.new().named("run").call_on_enter(run_start).call_on_update(run_process)
	var jump_state = LimboState.new().named("jump").call_on_enter(jump_start).call_on_update(jump_process)
	var fall_state = LimboState.new().named("fall").call_on_enter(fall_start).call_on_update(fall_process)
	var attack_state = LimboState.new().named("attack").call_on_enter(attack_start).call_on_update(attack_process)
	var crouch_state = LimboState.new().named("crouch").call_on_enter(crouch_start).call_on_update(crouch_process)
	var heal_state = LimboState.new().named("heal").call_on_enter(heal_start).call_on_update(heal_process)
	var block_state = LimboState.new().named("block").call_on_enter(block_start).call_on_update(block_process)
	var die_state = LimboState.new().named("die").call_on_enter(die_start).call_on_update(die_process)
	
	main_sm.add_child(idle_state)
	main_sm.add_child(walk_state)
	main_sm.add_child(run_state)
	main_sm.add_child(jump_state)
	main_sm.add_child(fall_state)
	main_sm.add_child(attack_state)
	main_sm.add_child(crouch_state)
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
	main_sm.add_transition(main_sm.ANYSTATE, crouch_state, &"go_crouch")
	main_sm.add_transition(main_sm.ANYSTATE, heal_state, &"go_heal")
	main_sm.add_transition(main_sm.ANYSTATE, block_state, &"go_block")
	main_sm.add_transition(main_sm.ANYSTATE, die_state, &"go_die")
	
	main_sm.initialize(self)
	main_sm.set_active(true)

# IDLE

func idle_start():
	if !can_control: return
	animator.play("idle")

func idle_process(_delta: float):
	if !can_control: return
	if currenthealth < 40:
		animator.play("damaged_idle")
	if dir != 0:
		if Input.is_action_pressed("run"):
			main_sm.dispatch(&"go_run")
		else:
			main_sm.dispatch(&"go_walk")
	if currenthealth <= 0:
		main_sm.dispatch(&"go_die")

# WALK

func walk_start():
	if !can_control: return
	animator.play("walk")

func walk_process(_delta: float):
	if !can_control: return
	if Input.is_action_pressed("run"):
		main_sm.dispatch(&"go_run")
	elif dir == 0:
		main_sm.dispatch(&"state_ended")
	if currenthealth <= 0:
		main_sm.dispatch(&"go_die")

# RUN

func run_start():
	if !can_control: return
	animator.play("run")

func run_process(_delta: float):
	if !can_control: return
	if Input.is_action_just_released("run") or dir == 0:
		if dir != 0:
			main_sm.dispatch(&"go_walk")
		elif dir == 0:
			main_sm.dispatch(&"state_ended")
	if currenthealth <= 0:
		main_sm.dispatch(&"go_die")

# JUMP

func jump_start():
	if !can_control: return
	animator.play("jump")
	is_jumping = true
	velocity.y = Jump_Velocity

func jump_process(_delta: float):
	if !can_control: return
	if Input.is_action_just_released("jump"):
		velocity.y *= 0.4
	if is_on_floor():
		is_jumping = false
		if Input.is_action_pressed("run") and dir != 0:
			main_sm.dispatch(&"go_run")
		elif dir != 0:
			main_sm.dispatch(&"go_walk")
		else:
			main_sm.dispatch(&"state_ended")
		if currenthealth <= 0:
			main_sm.dispatch(&"go_die")

# FALL

func fall_start():
	if !can_control: return
	animator.play("fall")
	is_falling = true

func fall_process(_delta: float):
	if !can_control: return
	if is_on_floor():
		is_falling = false
		is_jumping = false
		if Input.is_action_pressed("run") and dir != 0:
			is_falling = false
			main_sm.dispatch(&"go_run")
		elif dir != 0:
			is_falling = false
			main_sm.dispatch(&"go_walk")
		else:
			is_falling = false
			main_sm.dispatch(&"state_ended")
		if currenthealth <= 0:
			is_falling = false
			main_sm.dispatch(&"go_die")

# ATTACK

func attack_start():
	if !can_control: return
	is_attacking = true
	attack_cooldown.start()
	combo_timer.start()
	if combo_state == 0:
		animator.play("attack 1")
	elif combo_state == 1:
		animator.play("attack 2")
	elif combo_state == 2:
		animator.play("attack 3")
	can_attack = false

func attack_process(_delta: float):
	if !can_control: return
	if animator.is_playing(): return
	if combo_state == 0:
		combo_state = 1
	elif combo_state == 1:
		combo_state = 2
	elif combo_state == 2:
		combo_state = 0
	if Input.is_action_pressed("run") and dir != 0:
		is_attacking = false
		main_sm.dispatch(&"go_run")
	elif dir != 0:
		is_attacking = false
		main_sm.dispatch(&"go_walk")
	else:
		is_attacking = false
		main_sm.dispatch(&"state_ended")
	if currenthealth <= 0:
		main_sm.dispatch(&"go_die")

# CROUCH

func crouch_start():
	if !can_control: return
	is_crouching = true
	collision.shape = CROUTCH
	collision.position.y = 4.5
	animator.play("crouch")

func crouch_process(_delta: float):
	if !can_control: return
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
		if currenthealth <= 0:
			main_sm.dispatch(&"go_die")

# HEAL

func heal_start():
	if !can_control: return
	animator.play("heal")
	is_healing = true
	currenthealth = min(currenthealth + 30, 100)
	HealthBottles.health_bottles -= 1

func heal_process(_delta: float):
	if !can_control: return
	if animator.is_playing(): return
	if Input.is_action_just_released("run"):
		if dir != 0:
			is_healing = false
			main_sm.dispatch(&"go_walk")
		else:
			is_healing = false
			main_sm.dispatch(&"go_walk")
	elif dir == 0:
		is_healing = false
		main_sm.dispatch(&"state_ended")
	if currenthealth <= 0:
		main_sm.dispatch(&"go_die")

# BLOCK

func block_start():
	if !can_control: return
	animator.play("block")
	is_blocking = true

func block_process(_delta: float):
	if !can_control: return
	if animator.is_playing(): return
	if Input.is_action_pressed("run") and dir != 0:
		is_blocking = false
		main_sm.dispatch(&"go_run")
	elif dir != 0:
		is_blocking = false
		main_sm.dispatch(&"go_walk")
	else:
		is_blocking = false
		main_sm.dispatch(&"state_ended")
	if currenthealth <= 0:
		main_sm.dispatch(&"go_die")

# DIE

func die_start():
	animator.play("die")
	
func die_process(_delta: float):
	if is_reloading: return
	is_reloading = true
	await get_tree().create_timer(2).timeout
	get_tree().reload_current_scene()

# END
