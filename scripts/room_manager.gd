extends Node

@export var camera: Camera2D
@export var player: CharacterBody2D

var current_room: GameRoom = null
var is_transitioning: bool = false # 锁，防止在切图动画期间重复触发

func _ready():
	current_room = $Dorm1

func _physics_process(_delta: float) -> void:
	if is_transitioning or not player:
		return
		
	# 【核心核心】检查玩家当前的位置在哪个房间的范围内
	for child in get_children():
		if child is GameRoom:
			var bounds = child.get_room_bounds()
			# 使用 has_point 检测玩家的全局坐标是否在这个房间矩形内
			if bounds.has_point(player.global_position):
				if current_room != child:
					_on_room_changed(child)
				break # 找到了就立马跳出循环

func _on_room_changed(target_room: GameRoom) -> void:
	is_transitioning = true
	current_room = target_room
	print("进入新房间: ", current_room.name)
	
	var bounds = current_room.get_room_bounds()
	_update_camera_limits(bounds)
	
	if player.has_method("set_respawn_point"):
		player.set_respawn_point(current_room.spawn_point.global_position)

func _update_camera_limits(bounds: Rect2) -> void:
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(camera, "limit_left", int(bounds.position.x), 0.5)
	tween.tween_property(camera, "limit_top", int(bounds.position.y), 0.5)
	tween.tween_property(camera, "limit_right", int(bounds.end.x), 0.5)
	tween.tween_property(camera, "limit_bottom", int(bounds.end.y), 0.5)
	
	player.room_freeze()
		
	# 动画结束，把锁解开
	tween.chain().tween_callback(func():
		is_transitioning = false # 允许下一次切图判定
		player.room_unfreeze()
	)

# 当玩家死亡时，由玩家或者全局控制器调用此函数
func respawn_player() -> void:
	if current_room:
		# 1. 重置当前房间的机关状态（比如吃掉的水晶重新变亮）
		# current_room.reset_room()
		# 2. 把玩家拉回出生点并重置玩家状态（如重置冲刺次数、速度清零）
		player.global_position = current_room.spawn_point.global_position
		if player.has_method("reset_player_state"):
			player.reset_player_state()
