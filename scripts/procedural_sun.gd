@tool
extends Node2D

# 实际用于绘制的隐藏半径
var _radius: float = 10.0

func _draw() -> void:
	# 用像素带绘制，确保左右上下绝对对称
	var r_squared = _radius * _radius
	var max_y = int(ceil(_radius))
	
	for y in range(-max_y, max_y + 1):
		var diff = r_squared - (y * y)
		if diff >= 0:
			var max_x = int(sqrt(diff))
			# max_x * 2 + 1 保证奇数宽度，绝对不会偏心
			draw_rect(Rect2(-max_x, y, max_x * 2 + 1, 1), Color.WHITE)

# 主控脚本每帧调用的接口
func update_radius(new_radius: float) -> void:
	var integer_part = floor(new_radius)
	var fraction = new_radius - integer_part
	
	# 【核心优化】实现你说的小数拦截逻辑
	# 如果小数部分在 0.0 到 0.05 之间（刚超过整数一点点）
	# 就强行减去一个 eps (0.01)，把它压回到上一档整数的 0.99，防止边缘单像素突变 popping
	var eps = 0.01
	if fraction >= 0.0 and fraction < 0.05:
		new_radius = integer_part - eps
		
	# 只有当过滤后的半径真的变了，才触发重绘
	if not is_equal_approx(_radius, new_radius):
		_radius = new_radius
		queue_redraw()