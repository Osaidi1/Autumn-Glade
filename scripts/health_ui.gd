extends TextureProgressBar

@onready var health_bar: TextureProgressBar = $"."

var health = 0 : set = _set_health

func _set_health(new_health):
	health = min(max_value, new_health)
	value = health

func init_health(_health):
	health = _health
	max_value = health
	value = health
