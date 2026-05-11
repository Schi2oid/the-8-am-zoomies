extends Camera2D

# --- 可调参数 ---
@export var spring_stiffness = 3000.0 # 弹簧硬度：越大回弹越快
@export var spring_damping = 20.0    # 阻尼：越大回震次数越少，越小晃动时间越长
@export var max_displacement = 20.0 # 冲刺瞬间的最大位移

var target_offset = Vector2.ZERO    # 目标位置（永远是原点）
var current_velocity = Vector2.ZERO # 摄像机当前的移动速度

func _physics_process(delta):

	var displacement = offset - target_offset
	
	# 计算弹簧力 (F = -kx)
	var spring_force = -spring_stiffness * displacement
	
	# 计算阻尼力 (阻止永远晃动)
	var damping_force = -spring_damping * current_velocity
	
	# 计算加速度并更新速度和位置
	var acceleration = spring_force + damping_force
	current_velocity += acceleration * delta
	offset += current_velocity * delta

# --- 外部调用接口 ---
func apply_directional_shake(strength: float, direction: Vector2):
	# strength 范围 0 到 1
	# 冲刺瞬间，直接给 offset 给一个初始的位移
	# 这个位移会触发上面的弹簧逻辑，自动产生“过量回震”
	offset = direction.normalized() * max_displacement * strength
	
	# 如果想要更猛一点，也可以同时给一个初始速度
	current_velocity = direction.normalized() * max_displacement * strength * 10
