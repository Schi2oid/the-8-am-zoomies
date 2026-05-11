extends ColorRect


func _ready():
	material = material.duplicate()
	$AnimationPlayer.play("SprintBlast")
