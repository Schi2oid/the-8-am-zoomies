extends Line2D

@export var length: int = 10         # 增加节点数，让曲线更柔顺
@export var spacing: float = 2       # 节点间的固定间距
@export var stiffness: float = 0.8    # 追随速度 (0-1)
@export var gravity: Vector2 = Vector2(0, 600) # 稍微给一点下坠感

@export var swing_speed: float = 2.4  # 摆动速度
@export var swing_range: float = 10.0  # 摆动幅度
@export var wave_offset: float = 0.5  # 节点间的相位差（产生S形波浪感）
@export var pos: Vector2 = Vector2(-7.0, 2.0)

var points_pos: Array[Vector2] = []
var time_passed: float = 0.0
var visual: Node2D
var special_judge:bool = false

func _ready():
		
	top_level = false
	
	visual = get_tree().root.find_child("Visual", true, false)
	print(visual.name)
	points_pos.clear()
	for i in range(length):
		points_pos.append(pos + visual.global_position)
	
	# 设置 Line2D 样式
	width = 5.0
	var gradient_res = Gradient.new()
	gradient_res.set_color(1, Color("4d3f3dff")) # 头部颜色
	gradient_res.set_color(0, Color("a38e8bff")) # 尾部颜色
	gradient = gradient_res
	
func _process(delta: float):
	if(special_judge == true):
		return
	var gradient_res = Gradient.new()
	var tmp = true
	if tmp == true:
		gradient_res.set_color(1, Color("4d3f3dff")) # 头部颜色
		gradient_res.set_color(0, Color("a38e8bff")) # 尾部颜色
	else:
		print("WHAT?")
		gradient_res.set_color(1, Color("4d3f3dff")) # 头部颜色
		gradient_res.set_color(0, Color("241f1eff")) # 尾部颜色
	gradient = gradient_res
	global_position = Vector2.ZERO
	
	if(pos.x * visual.scale.x > 0):
		pos.x = -pos.x
	time_passed += delta
	
	points_pos[0] = pos + visual.global_position
	
	for i in range(1, length):
		var wave = sin(time_passed * swing_speed + (i * wave_offset))
		var swing_vector = Vector2(wave * swing_range * (sqrt(float(i)) / length), 0)
		points_pos[i] += gravity * delta
		points_pos[i] += swing_vector * delta * 10.0
		
		var diff = points_pos[i] - points_pos[i-1]
		var distance = diff.length()
		
		if distance > spacing:
			var direction = diff.normalized()
			var target_pos = points_pos[i-1] + direction * spacing
			if(pos.x < 0):
				target_pos.x -= 0.05
			else:
				target_pos.x += 0.05
			points_pos[i] = points_pos[i].lerp(target_pos, stiffness)

	points = PackedVector2Array(points_pos)
