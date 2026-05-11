extends AnimatedSprite2D

var special_judge:bool = false
var visual: Node2D

func _ready():
	top_level = false
	visual = get_tree().root.find_child("Visual", true, false)

func _process(_delta: float):
	if(special_judge == true):
		return
	global_position = visual.global_position
	scale.x=visual.scale.x
	
