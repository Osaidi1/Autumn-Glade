extends Area2D

@onready var player1: Player = $"../player"
@onready var player: Player = $"../player"

#Body has entered area
func _on_body_entered(body):
	if body is Player:
		await get_tree().create_timer(1).timeout
		get_tree().reload_current_scene()
