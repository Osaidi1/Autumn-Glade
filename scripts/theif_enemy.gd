extends CharacterBody2D

@export var player: CharacterBody2D
@export var CHASESPEED = 100
@export var SPEED = 50
@export var ACCELERATION = 150

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_2d: RayCast2D = $AnimatedSprite2D/RayCast2D
@onready var timer: Timer = $Timer

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: Vector2
var right_bounds: Vector2
var left_bounds: Vector2

enum States {
	WANDER,
	CHASE,
	HIT,
	DIE
}

var current_state = States.WANDER

func _ready() -> void:
	left_bounds = self.position + Vector2(-200, 0)
	right_bounds = self.position + Vector2(200, 0)

func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	handle_movement(delta)
	change_direction()
	look_for_player()
	move_and_slide()

func look_for_player():
	if ray_cast_2d.is_colliding():
		var collider = ray_cast_2d.get_collider()
		if collider == player:
			chase_player()
	elif current_state == States.CHASE:
			stop_chase()

func chase_player():
	timer.stop()
	current_state = States.CHASE

func stop_chase():
	if timer.time_left <= 0:
		timer.start()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_movement(delta):
	if current_state == States.WANDER:
		velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(direction * CHASESPEED, ACCELERATION * delta)

func change_direction():
	if current_state == States.WANDER:
		if sprite.flip_h:
			if self.position.x <= right_bounds.x:
				direction = Vector2(1, 0)
			else:
				sprite.flip_h = false
				ray_cast_2d.target_position = Vector2(-125, 0)
		else:
			if self.position.x >= left_bounds.x:
				direction = Vector2(-1, 0)
			else:
				sprite.flip_h = true
				ray_cast_2d.target_position = Vector2(125, 0)
	else:
		direction = (player.position - self.position).normalized()
		direction = Vector2(sign(direction.x), sign(direction.y))

		if direction.x == 1:
			sprite.flip_h = false
			ray_cast_2d.target_position = Vector2(125, 0)
		else:
			sprite.flip_h = true
			ray_cast_2d.target_position = Vector2(-125,0)

func _on_timer_timeout() -> void:
	current_state = States.WANDER
