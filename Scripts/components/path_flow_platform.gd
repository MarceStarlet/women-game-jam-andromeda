extends AnimatableBody2D

@export var move_speed = 0.5

@onready var path_follow: PathFollow2D = get_parent()

var path_direction = 1

func _physics_process(delta: float) -> void:
	path_follow.progress += move_speed * path_direction
	var new_progess_ratio = path_follow.progress_ratio
	if new_progess_ratio == 0 || new_progess_ratio == 1:
		path_direction *= -1
