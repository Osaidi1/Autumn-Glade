extends Area2D

#Body has entered area
func _on_body_entered(body):
	if body is Player:
		await get_tree().create_timer(1).timeout
		get_tree().reload_current_scene()
