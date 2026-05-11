extends Camera2D

# --- 可调参数 ---
@export var spring_stiffness = 3000.0 # 弹簧硬度：越大回弹越快
@export var spring_damping = 20.0    # 阻尼：越大回震次数越少，越小晃动时间越长
@export var max_displacement = 30.0 # 冲刺瞬间的最大位移

var target_offset = Vector2.ZERO
var current_velocity = Vector2.ZERO
var real_position = Vector2.ZERO

func smoothly_follow():
	var target_position = get_parent().global_position
	real_position = lerp(real_position, target_position, 0.07)
	var dis = real_position - target_position
	global_position = target_position + dis.round()
	
func _ready():
	real_position = global_position

func _physics_process(delta):
	smoothly_follow()

	var displacement = offset - target_offset
	
	var spring_force = -spring_stiffness * displacement
	
	var damping_force = -spring_damping * current_velocity
	
	var acceleration = spring_force + damping_force
	current_velocity += acceleration * delta
	offset += current_velocity * delta

	

# --- 外部调用接口 ---
func apply_directional_shake(strength: float, direction: Vector2):
	offset = direction.normalized() * max_displacement * strength
	current_velocity = direction.normalized() * max_displacement * strength
