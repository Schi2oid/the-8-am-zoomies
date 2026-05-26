extends Node2D
class_name GameRoom

@onready var collision_shape: CollisionShape2D = $BoundedArea/CollisionShape2D
@onready var spawn_point: Marker2D = $SpawnPoint

func get_room_bounds() -> Rect2:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect_shape = collision_shape.shape as RectangleShape2D
		var size = rect_shape.size
		var top_left = collision_shape.global_position - (size / 2)
		return Rect2(top_left, size)
	return Rect2()