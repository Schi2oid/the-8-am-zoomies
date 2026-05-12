extends Node2D

# --- 核心物理参数 ---
@export var length: int = 10 
@export var spacing: float = 1.0 
@export var stiffness: float = 0.6 
@export var gravity: Vector2 = Vector2(0, -30) # 向上飘

# --- 摆动与滚动参数 ---
@export var swing_speed: float = 2.4 
@export var swing_range: float = 10.0 
@export var wave_offset: float = 0.5 
@export var pos: Vector2 = Vector2(-7.0, 2.0) 

# --- 像素圆绘图参数 ---
@export var radius_start: float = 3.2   # 修改为 float
@export var radius_end: float = 1.8     # 修改为 float
@export var color_head: Color = Color("4d3f3dff")
@export var color_tail: Color = Color("a38e8bff")

# --- 内部变量 ---
var relative_points: Array[Vector2] = [] 
var prev_root_global: Vector2 = Vector2.ZERO 
var time_passed: float = 0.0
var visual: Node2D
var special_judge: bool = false
var is_rolling: bool = false
var rot: float = 1.0

func _ready():
	visual = get_tree().root.find_child("Visual", true, false)
	relative_points.clear()
	for i in range(length):
		relative_points.append(Vector2(0, -i * spacing))
	prev_root_global = visual.to_global(pos)

func _physics_process(delta: float):
	if special_judge: return
	rot = sign(visual.scale.x)
	time_passed += delta
	
	var current_root_global: Vector2
	if is_rolling:
		var roll_speed = 3.0 * 2.0 * PI * rot
		var angle = (PI + time_passed * roll_speed) if rot == 1.0 else (time_passed * roll_speed)
		current_root_global = visual.global_position + Vector2(cos(angle), sin(angle)) * 6.0
	else:
		current_root_global = visual.to_global(pos)
		
	var root_movement = current_root_global - prev_root_global
	prev_root_global = current_root_global 
	
	relative_points[0] = Vector2.ZERO 

	# 物理逻辑更新
	for i in range(1, length):
		relative_points[i] -= root_movement 
		
		if is_rolling:
			if(visual.global_position.distance_to(current_root_global + relative_points[i]) > 12.0):
				relative_points[i] = relative_points[i].lerp(relative_points[i-1], stiffness)
				continue
			var roll_speed = 3.0 * 2.0 * PI * rot
			var angle = (PI + time_passed * roll_speed - (i * 0.3)) if rot == 1.0 else (time_passed * roll_speed + (i * 0.3))
			var target_rel = (visual.global_position + Vector2(cos(angle), sin(angle)) * 8.0) - current_root_global
			relative_points[i] = relative_points[i].lerp(target_rel, stiffness)
		else:
			var wave = sin(time_passed * swing_speed + (i * wave_offset))
			var swing_x = wave * swing_range * (sqrt(float(i)) / length)
			
			relative_points[i] += gravity * delta
			relative_points[i].x += swing_x * delta * 10.0
			
			var diff = relative_points[i] - relative_points[i-1]
			if diff.length() > spacing:
				var target_pos = relative_points[i-1] + diff.normalized() * spacing
				target_pos.x += (-0.05 if visual.scale.x > 0 else 0.05)
				relative_points[i] = relative_points[i].lerp(target_pos, stiffness)

	queue_redraw()

func _draw():
	# 保持原点带有小数，以同步主角的亚像素位移
	var exact_draw_origin = prev_root_global - global_position
	
	for i in range(length):
		var t = float(i) / float(length - 1 if length > 1 else 1)
		
		# 【修改】：保留浮点半径，不进行 int 转换
		var r = lerp(radius_start, radius_end, t)
		var color = color_head.lerp(color_tail, t)
		
		# 内部坐标取整，确保像素对齐逻辑
		var center = exact_draw_origin + relative_points[i].round()
		
		draw_perfect_pixel_circle(center, r, color)

## 核心函数：支持浮点半径的完美像素圆
func draw_perfect_pixel_circle(center: Vector2, radius: float, color: Color):
	if radius <= 0.0:
		return
	
	# 极小半径处理
	if radius < 0.5:
		draw_rect(Rect2(center, Vector2(1, 1)), color)
		return
		
	# 确定采样范围：向上取整确保覆盖边缘
	var ceil_r = int(ceil(radius))
	var r_sq = radius * radius
	
	# 遍历局部像素网格
	for y in range(-ceil_r, ceil_r + 1):
		for x in range(-ceil_r, ceil_r + 1):
			# 标准圆方程：距离平方 <= 半径平方
			if x*x + y*y <= r_sq:
				# center 携带亚像素偏移，(x, y) 保证了像素块的相对完整
				draw_rect(Rect2(center + Vector2(x, y), Vector2(1, 1)), color)

# 控制接口
func start_rolling(): is_rolling = true; time_passed = 0.0
func stop_rolling(): is_rolling = false
