extends TextureProgressBar

@onready var health_bar: TextureProgressBar = $"."

func change_health(currenthealth):
	value = currenthealth
