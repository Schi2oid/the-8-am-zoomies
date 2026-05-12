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
@export var radius_start: int = 4   
@export var radius_end: int = 2     
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
	# 【核心改动 1】：绝对不取整！保留主角的亚像素小数部分
	var exact_draw_origin = prev_root_global - global_position
	
	for i in range(length):
		var t = float(i) / float(length - 1 if length > 1 else 1)
		var r = int(lerp(radius_start, radius_end, t))
		var color = color_head.lerp(color_tail, t)
		
		# 【核心改动 2】：仅仅对内部相对坐标取整。
		# 浮点原点 + 纯整数偏移 = 保证该中心点的小数部分与主角绝对一致！
		var center = exact_draw_origin + relative_points[i].round()
		
		draw_perfect_pixel_circle(center, r, color)

## 核心函数：绘制完美像素圆，同时保留坐标小数部分
func draw_perfect_pixel_circle(center: Vector2, radius: int, color: Color):
	if radius <= 0:
		# 半径为 0 时，在拥有精确小数坐标的 center 位置绘制 1x1 像素
		draw_rect(Rect2(center, Vector2(1, 1)), color)
		return
		
	# 在局部的整数网格中遍历
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			# 中点圆判定算法 (使用 + 0.5 让边缘圆润对称)
			if x*x + y*y <= (radius * radius + radius * 0.5):
				# center 带有小数，x 和 y 是纯整数
				# 这意味着生成的每一个 Rect 的起始坐标，都完美携带了主角的亚像素偏移！
				draw_rect(Rect2(center + Vector2(x, y), Vector2(1, 1)), color)

# 控制接口
func start_rolling(): is_rolling = true; time_passed = 0.0
func stop_rolling(): is_rolling = false
