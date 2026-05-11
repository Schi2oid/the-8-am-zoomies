extends Line2D

@export var length: int = 10         # 增加节点数，让曲线更柔顺
@export var spacing: float = 1.0       # 节点间的固定间距
@export var stiffness: float = 0.4    # 追随速度 (0-1)
@export var gravity: Vector2 = Vector2(0, 600) # 稍微给一点下坠感

@export var swing_speed: float = 2.4  # 摆动速度
@export var swing_range: float = 10.0  # 摆动幅度
@export var wave_offset: float = 0.5  # 节点间的相位差（产生S形波浪感）
@export var pos: Vector2 = Vector2(-7.0, 2.0)

var points_pos: Array[Vector2] = []
var real_points_pos: Array[Vector2] = []
var time_passed: float = 0.0
var visual: Node2D
var special_judge:bool = false
var is_rolling = true
var rot = 1.0

func start_rolling():
	is_rolling = true
	time_passed = 0.0

func stop_rolling():
	is_rolling = false

func _ready():
	
	visual = get_tree().root.find_child("Visual", true, false)
	points_pos.clear()
	real_points_pos.clear()
	for i in range(length):
		real_points_pos.append(pos + visual.global_position)
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
	global_position = Vector2.ZERO
	
	if(pos.x * visual.scale.x > 0):
		rot = -rot
		pos.x = -pos.x
	time_passed += delta
	if is_rolling:
		var roll_speed = 3.0 * 2.0 * PI * rot
		var angle
		if rot == 1.0:
			angle = PI + time_passed * roll_speed
		else:
			angle = time_passed * roll_speed
		real_points_pos[0] = visual.global_position + Vector2(cos(angle), sin(angle)) * 6.0
	else: real_points_pos[0] = pos + visual.global_position
	
	if is_rolling:
		var roll_speed = 3.0 * 2.0 * PI * rot
		for i in range(1, length):
			var angle
			if rot == 1.0:
				angle = PI + time_passed * roll_speed - (i * 0.3)
			else:
				angle = time_passed * roll_speed + (i * 0.3)
			var target_circle_pos = visual.global_position + Vector2(cos(angle), sin(angle)) * 8.0
			real_points_pos[i] = real_points_pos[i].lerp(target_circle_pos, stiffness)
	else:
		for i in range(1, length):
			var wave = sin(time_passed * swing_speed + (i * wave_offset))
			var swing_vector = Vector2(wave * swing_range * (sqrt(float(i)) / length), 0)
			real_points_pos[i] += gravity * delta
			real_points_pos[i] += swing_vector * delta * 10.0
			
			var diff = real_points_pos[i] - real_points_pos[i-1]
			var distance = diff.length()
			
			if distance > spacing:
				var direction = diff.normalized()
				var target_pos = real_points_pos[i-1] + direction * spacing
				if(pos.x < 0):
					target_pos.x -= 0.05
				else:
					target_pos.x += 0.05
				real_points_pos[i] = real_points_pos[i].lerp(target_pos, stiffness)
	
	print(real_points_pos[length-1])
	points = PackedVector2Array(real_points_pos)
	
