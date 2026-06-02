extends Node2D

@export_group("全天候时间控制")
@export_range(0.0, 1.0) var time_of_day: float = 0.0 
@export var day_speed: float = 0.02
@export var is_looping: bool = false 

@export_group("太阳运行轨迹")
@export var default_resolution: Vector2 = Vector2(1152, 648) 
@export var sun_base_position_x: float = 576.0 

@export var sun_rise_start_time: float = 0.2
@export var sun_rise_end_time: float = 0.7

@export_group("太阳边缘优化参数")
@export var sun_base_radius: float = 8.0      
@export var sun_horizon_multiplier: float = 2.2 
@export var sun_growth_exponent: float = 2.5    

# 优化地平线 Y 轴：确保放大后的圆底边缘也能丝滑藏进视野外
@export var sun_y_below_horizon: float = 780.0 
@export var sun_y_high_noon: float = 120.0

@export_group("动画色彩与染色曲线")
@export var dawn_color_curve: Gradient 

@export_group("节点引用绑定")
@onready var sky_color_rect: ColorRect = $SkyLayer/SkyColorRect
@onready var sun_layer: Parallax2D = $SunLayer
@onready var sun_node: Node2D = $SunLayer/ProceduralSun 
@onready var cloud_far: ColorRect = $DistantClouds/CloudRectFar
@onready var cloud_near: ColorRect = $NearClouds/CloudRectNear

func _ready() -> void:
	if not dawn_color_curve:
		dawn_color_curve = Gradient.new()
		dawn_color_curve.set_color(0, Color("201c3d")) 
		dawn_color_curve.set_color(1, Color("bce2f4")) 
		dawn_color_curve.add_point(0.25, Color("cf574b")) 
		dawn_color_curve.add_point(0.5, Color("f6a845"))  
		dawn_color_curve.add_point(0.75, Color("fcd581")) 

func _process(delta: float) -> void:
	# 1. 驱动时间轴
	if is_looping:
		time_of_day = wrapf(time_of_day + day_speed * delta, 0.0, 1.0)
	else:
		time_of_day = clamp(time_of_day + day_speed * delta, 0.0, 1.0)
	
	# 2. 驱动全程序天空 Shader
	if is_instance_valid(sky_color_rect) and sky_color_rect.material is ShaderMaterial:
		var sky_mat = sky_color_rect.material as ShaderMaterial
		sky_mat.set_shader_parameter("time_of_day", time_of_day)
	
	# 用于存储供云层同步使用的太阳实时屏幕位置
	var normalized_sun_pos = Vector2(0.5, 0.5)
	
	# 3. 驱动程序化太阳及边缘防突变算法
	var current_dawn_color: Color = Color.WHITE
	if dawn_color_curve:
		current_dawn_color = dawn_color_curve.sample(time_of_day)

	if is_instance_valid(sun_node) and is_instance_valid(sun_layer):
		# A. 轨迹线性插值与像素四舍五入对齐
		var sun_rise_progress = clamp(remap(time_of_day, sun_rise_start_time, sun_rise_end_time, 0.0, 1.0), 0.0, 1.0)
		var target_y = lerp(sun_y_below_horizon, sun_y_high_noon, sun_rise_progress)
		var screen_scale = get_viewport_rect().size / default_resolution
		
		var final_sun_pos = Vector2(sun_base_position_x, target_y) * screen_scale
		sun_node.position = final_sun_pos.round()
		
		# 【新核心】：计算当前太阳在视口（Screen）中的 0.0 ~ 1.0 相对坐标
		var viewport_size = get_viewport_rect().size
		if viewport_size.x > 0.0 and viewport_size.y > 0.0:
			normalized_sun_pos = sun_node.get_global_transform_with_canvas().origin / viewport_size
		
		# B. 主控精确缩放驱动
		var t = 1.0 - sun_rise_progress 
		t = pow(t, sun_growth_exponent)
		var current_radius = lerp(sun_base_radius, sun_base_radius * sun_horizon_multiplier, t)
		
		if sun_node.has_method("update_radius"):
			sun_node.update_radius(current_radius)

		# C. 驱动 Bloom 过曝光能量
		var bloom_intensity: float = 1.0
		if time_of_day > 0.25 and time_of_day <= 0.5:
			bloom_intensity = remap(time_of_day, 0.25, 0.5, 1.0, 2.5)
		elif time_of_day > 0.5 and time_of_day <= 0.75:
			bloom_intensity = remap(time_of_day, 0.5, 0.75, 2.5, 1.0)
		
		sun_node.modulate = current_dawn_color * bloom_intensity

	# =========================================================================
	# 4. 驱动多层云层的高级动态色调与太阳距离联动
	# =========================================================================
	var active_clouds: Array[ColorRect] = []
	if is_instance_valid(cloud_far): active_clouds.append(cloud_far)
	if is_instance_valid(cloud_near): active_clouds.append(cloud_near)
	
	for cloud in active_clouds:
		if cloud.material is ShaderMaterial:
			var cloud_mat = cloud.material as ShaderMaterial
			# 注入当前的全局时间线
			cloud_mat.set_shader_parameter("time_of_day", time_of_day)
			# 注入刚刚算好的太阳实时屏幕 0~1 坐标
			cloud_mat.set_shader_parameter("sun_screen_pos", normalized_sun_pos)