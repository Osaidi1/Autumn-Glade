extends CharacterBody2D

const walk_speed = 50
const run_speed = 200
var SPEED = 300.0
var JUMP_VELOCITY = -280.0
@onready var animator: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	#Handle Left Right Changes
	var direction = Input.get_axis("left", "right")
	if direction < 0:
		animator.flip_h = true
	elif direction > 0:
		animator.flip_h = false
	
	#Handle Speed Change
	if Input.is_action_pressed("run"):
		SPEED = run_speed
	else:
		SPEED = walk_speed
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animator.play("jump")
		
	#Play Animations
	if is_on_floor():
		if direction == 0:
			animator.play("idle")
		else:
			if Input.is_action_pressed("run"):
				animator.play("run")
			else:
				animator.play("walk")
	
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
	
	move_and_slide()
