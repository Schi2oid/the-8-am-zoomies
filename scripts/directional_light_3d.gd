extends DirectionalLight3D

@export_group("Time Settings")
@export var day_duration: float = 20.0  # 日出过程持续时间（秒）
@export var start_angle: float = -15.0  # 太阳起始角度（黑夜）
@export var end_angle: float = 20.0    # 太阳结束角度（完全升起）

@export_group("2D Sync")
@export var canvas_modulate: CanvasModulate # 引用 2D 环境光节点

@export_group("Cloud Settings")
@export var cloud_material: ShaderMaterial # 云层材质引用

var current_time: float = 0.0

func _process(delta):
	if current_time < day_duration:
		current_time += delta
		
		# 1. 计算太阳旋转角度
		var progress = current_time / day_duration
		var current_angle = lerp(start_angle, end_angle, progress)
		
		# 这里的旋转控制太阳升起
		rotation_degrees.x = current_angle
		
		# 2. 同步环境光到 2D
		# 我们利用 light_color 和 light_intensity 的变化来驱动 2D 的亮度
		if canvas_modulate:
			sync_2d_environment(progress)
		
		# 3. 更新云层颜色以匹配日出效果
		if cloud_material:
			update_cloud_colors(progress)
		
		# 4. 更新光源本身的颜色和强度
		update_light_color_and_energy(progress)

func sync_2d_environment(progress):
	# 定义黑夜和白天的环境颜色
	var night_color = Color("1a1a2e") # 深蓝色
	var sunrise_color = Color("ff5e3a") # 橘红色
	var day_color = Color("ffffff") # 正常白色
	
	var final_color: Color
	
	if progress < 0.5:
		# 黑夜到日出的过渡
		final_color = night_color.lerp(sunrise_color, progress * 2.0)
	else:
		# 日出到白天的过渡
		final_color = sunrise_color.lerp(day_color, (progress - 0.5) * 2.0)
	
	# 设置 2D 场景的整体色调
	canvas_modulate.color = final_color

func update_cloud_colors(progress):
	# 定义云层在不同时间段的太阳颜色
	var night_sun_color = Color(0.2, 0.2, 0.3, 1.0) # 夜晚的暗色
	var sunrise_sun_color = Color(1.0, 0.3, 0.1, 1.0) # 日出的橙红色
	var day_sun_color = Color(1.0, 0.95, 0.8, 1.0) # 白天的暖白色
	
	var final_sun_color: Color
	
	if progress < 0.5:
		# 黑夜到日出的过渡
		final_sun_color = night_sun_color.lerp(sunrise_sun_color, progress * 2.0)
	else:
		# 日出到白天的过渡
		final_sun_color = sunrise_sun_color.lerp(day_sun_color, (progress - 0.5) * 2.0)
	
	# 更新云层材质的太阳颜色参数
	cloud_material.set_shader_parameter("sun_color", final_sun_color)
	
	# 根据日出进度调整光透射强度
	var transmission_strength = 0.3
	if progress > 0.3 and progress < 0.7:
		# 在日出期间增加透射强度，使云层更红
		transmission_strength = 0.9
	elif progress >= 0.7:
		transmission_strength = 0.5
	
	cloud_material.set_shader_parameter("light_transmission", transmission_strength)

func update_light_color_and_energy(progress):
	# 定义不同时间段的光源颜色
	var night_light_color = Color(0.1, 0.1, 0.2, 1.0) # 夜晚的暗蓝色
	var sunrise_light_color = Color(1.0, 0.5, 0.2, 1.0) # 日出的橙红色
	var day_light_color = Color(1.0, 0.95, 0.9, 1.0) # 白天的暖白色
	
	var final_light_color: Color
	
	if progress < 0.5:
		# 黑夜到日出的过渡
		final_light_color = night_light_color.lerp(sunrise_light_color, progress * 2.0)
	else:
		# 日出到白天的过渡
		final_light_color = sunrise_light_color.lerp(day_light_color, (progress - 0.5) * 2.0)
	
	# 定义不同时间段的光源强度
	var night_energy = 0.1
	var sunrise_energy = 1.2
	var day_energy = 1.5
	
	var final_energy: float
	
	if progress < 0.5:
		final_energy = lerp(night_energy, sunrise_energy, progress * 2.0)
	else:
		final_energy = lerp(sunrise_energy, day_energy, (progress - 0.5) * 2.0)
	
	# 更新光源颜色和强度
	light_color = final_light_color
	light_energy = final_energy