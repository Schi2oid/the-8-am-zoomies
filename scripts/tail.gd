extends Line2D

@export var length: int = 10         # 增加节点数，让曲线更柔顺
@export var spacing: float = 1.0       # 节点间的固定间距
@export var stiffness: float = 0.4    # 追随速度 (0-1)
@export var gravity: Vector2 = Vector2(0, 600) # 稍微给一点下坠感

@export var swing_speed: float = 2.4  # 摆动速度
@export var swing_range: float = 10.0  # 摆动幅度
@export var wave_offset: float = 0.5  # 节点间的相位差（产生S形波浪感）
@export var pos: Vector2 = Vector2(-7.0, 2.0)

# relative_points 存储的是相对于根节点(第0个点)的相对向量
var relative_points: Array[Vector2] = [] 
var prev_root_global: Vector2 = Vector2.ZERO # 用于计算根节点的位移增量
var time_passed: float = 0.0
var visual: Node2D
var special_judge: bool = false
var is_rolling = true
var rot = 1.0

func start_rolling():
    is_rolling = true
    time_passed = 0.0

func stop_rolling():
    is_rolling = false

func _ready():
    visual = get_tree().root.find_child("Visual", true, false)
    print(visual.name)
    relative_points.clear()
    
    # 初始状态下，根节点在 0,0。其余节点按间距垂直向下排列
    for i in range(length):
        relative_points.append(Vector2(0, i * spacing))
        
    prev_root_global = pos + visual.global_position
    
    # 设置 Line2D 样式
    width = 5.0
    var gradient_res = Gradient.new()
    gradient_res.set_color(1, Color("4d3f3dff")) # 头部颜色
    gradient_res.set_color(0, Color("a38e8bff")) # 尾部颜色
    gradient = gradient_res
    
func _physics_process(delta: float):
    if special_judge == true:
        return
        
    # Line2D 本身的全局位置归零，我们将通过直接指定点坐标来绘制
    global_position = Vector2.ZERO
    
    if pos.x * visual.scale.x > 0:
        rot = -rot
        pos.x = -pos.x
    time_passed += delta
    
    # 1. 计算当前帧尾巴根部（第0个点）的全局位置
    var current_root_global: Vector2
    var roll_speed = 3.0 * 2.0 * PI * rot
    
    if is_rolling:
        var angle = (PI + time_passed * roll_speed) if rot == 1.0 else (time_passed * roll_speed)
        current_root_global = visual.global_position + Vector2(cos(angle), sin(angle)) * 6.0
    else:
        current_root_global = pos + visual.global_position
        
    # 2. 计算根节点的移动量（用于生成拖拽惯性）
    var root_movement = current_root_global - prev_root_global
    prev_root_global = current_root_global # 更新上一帧位置
    
    relative_points[0] = Vector2.ZERO # 锚点相对位置始终为 0

    # 3. 更新所有子节点的相对位置
    for i in range(1, length):
        # 【核心逻辑】：如果根节点移动了，其余节点受到反向的位移（模拟惯性和滞后）
        relative_points[i] -= root_movement 
        
        if is_rolling:
            var angle
            if rot == 1.0:
                angle = PI + time_passed * roll_speed - (i * 0.3)
            else:
                angle = time_passed * roll_speed + (i * 0.3)
            
            # 计算目标点的全局坐标，再转化为相对于当前根节点的相对坐标
            var target_circle_global = visual.global_position + Vector2(cos(angle), sin(angle)) * 8.0
            var target_relative = target_circle_global - current_root_global
            relative_points[i] = relative_points[i].lerp(target_relative, stiffness)
            
        else:
            # 下垂状态下的物理模拟
            var wave = sin(time_passed * swing_speed + (i * wave_offset))
            var swing_vector = Vector2(wave * swing_range * (sqrt(float(i)) / length), 0)
            
            # 在相对坐标上施加重力和摆动力
            relative_points[i] += gravity * delta
            relative_points[i] += swing_vector * delta * 10.0
            
            # 约束逻辑（保持节点间距）
            var diff = relative_points[i] - relative_points[i-1]
            var distance = diff.length()
            
            if distance > spacing:
                var direction = diff.normalized()
                var target_pos = relative_points[i-1] + direction * spacing
                
                # 保持你原有的 X 轴偏移小逻辑
                if pos.x < 0:
                    target_pos.x -= 0.05
                else:
                    target_pos.x += 0.05
                    
                relative_points[i] = relative_points[i].lerp(target_pos, stiffness)

    # 4. 将相对坐标转换回全局坐标，并进行【像素取整】
    var final_points: Array[Vector2] = []
    for i in range(length):
        var final_global_pos = current_root_global + relative_points[i]
        
        final_points.append(final_global_pos)
    points = PackedVector2Array(final_points)