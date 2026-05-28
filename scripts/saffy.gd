extends CharacterBody2D

# 定义状态
enum State { DOWN, IDLE, RUN, JUMP, FALL, DASH }

# --- 配置参数 ---
@export var speed = 90.0
@export var jump_velocity = -90.0
@export var acceleration = 1000.0
@export var friction = 800.0
@export var air_param = 0.65
@export var max_fall = 200.0
@export var gravity = 1200.0
@export var jump_hold_force = -1500.0  # 按住时的持续推力
@export var jump_max_time = 0.15       # 允许长按增加高度的最长时间
@export var dash_speed = 240.0         # 冲刺恒定速度 
@export var dash_duration = 0.15       # 冲刺持续约 9 帧 (60FPS) 
@export var shock_wavescene = preload("res://scenes/Shockwave.tscn")

# --- 内部变量 ---
var ghost_count = 0
var ghost_timer = 0.0
var is_frozen = false
var room_frozen = false
var can_dash = true                    # 落地恢复的冲刺次数 
var dash_timer = 0.0                   # 冲刺剩余时间计时器 
var dash_direction = Vector2.ZERO      # 存储冲刺发出的方向
var current_jump_timer = 0.0           # 倒计时变量
var is_jumping = false                 # 是否处于长按跳跃加力状态
var air_friction = friction * air_param
var on_floor = false
var temp_velocity = Vector2.ZERO
var active_ghost_tweens: Array[Tween] = [] # 新增：用于记录当前所有未淡出完毕的残影 Tween

@onready var visual = $Visual
@onready var anim = $AnimationPlayer
@onready var tail = $Visual/CanvasGroup/Tail

var current_state = State.IDLE

func room_freeze():
    room_frozen = true
    temp_velocity = velocity
    get_tree().call_group("ghost_timers", "set_deferred", "paused", true)
    anim.pause()
    if tail:
        tail.process_mode = Node.PROCESS_MODE_DISABLED
        
    for tween in active_ghost_tweens:
        if tween.is_valid():
            tween.pause()

func room_unfreeze():
    room_frozen = false
    velocity = temp_velocity
    get_tree().call_group("ghost_timers", "set_deferred", "paused", false)
    anim.play()
    if tail:
        tail.process_mode = Node.PROCESS_MODE_INHERIT
        
    for tween in active_ghost_tweens:
        if tween.is_valid():
            tween.play()
    can_dash = true

func spawn_shockwave():
    var sw = shock_wavescene.instantiate()
    get_tree().current_scene.add_child(sw)
    sw.global_position += global_position

func create_ghost_timer(delay: float):
    var timer = Timer.new()
    timer.wait_time = delay
    timer.one_shot = true
    timer.process_mode = Node.PROCESS_MODE_ALWAYS 
    timer.add_to_group("ghost_timers")
    add_child(timer)
    
    timer.timeout.connect(func():
        spawn_ghost()
        timer.queue_free()
    )
    timer.start()

func spawn_ghost():
    if current_state != State.DASH:
        return 
    ghost_count += 1
    var ghost = visual.duplicate()
    var cg = ghost.get_node("CanvasGroup")
    cg.material = cg.material.duplicate()
    cg.material.set_shader_parameter("is_ghost", true)
    var ghost_tail = ghost.get_node("CanvasGroup/Tail")
    if tail:
        ghost_tail.relative_points = tail.relative_points.duplicate()
        ghost_tail.prev_root_global = tail.prev_root_global
    ghost.get_node("CanvasGroup/Tail").special_judge = true
    ghost.get_node("CanvasGroup/Sprite2D").special_judge = true
    ghost.global_position = visual.global_position
    ghost.scale = visual.scale
    get_tree().current_scene.add_child(ghost)
    
    var tween = create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(cg, "modulate:a", 0.0, 0.4)
    
    active_ghost_tweens.append(tween)
    
    tween.finished.connect(func():
        active_ghost_tweens.erase(tween)
        ghost.queue_free()
    )
        
func _physics_process(delta):
    if(room_frozen):
        return

    if is_frozen == true:
        velocity = Vector2.ZERO
    
    move_and_slide()
    
    on_floor = is_on_floor()
    
    var input_dir = Input.get_axis("ui_left", "ui_right")
    
    handle_jump(delta)
    
    apply_state_transitions(input_dir)
    
    handle_physics(input_dir, delta)
    
    update_animation_effects(input_dir)

func start_dash_freeze(duration: float):
    is_frozen = true
    get_tree().paused = true
    velocity = Vector2.ZERO
    await get_tree().create_timer(duration, true, false, true).timeout
    get_tree().paused = false
    $Camera2D.apply_directional_shake(0.1, dash_direction)
    velocity = dash_direction * dash_speed
    can_dash = false
    is_frozen = false

func change_state(new_state):
    if current_state == new_state:
        return
        
    match current_state:
        State.FALL:
            if is_on_floor():
                anim.play("roll_after")
                $JumpDust.restart()
                $JumpDust.emitting = true
        State.DOWN:
            tail.pos.y -= 2.0

    match new_state:
        State.DASH:
            if on_floor == true:
                anim.play("roll_before")
            velocity = Vector2.ZERO
            can_dash = false
            dash_timer = dash_duration
            var input_v = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
            if input_v == Vector2.ZERO:
                dash_direction = Vector2(visual.scale.x, 0)
            else:
                dash_direction = input_v.normalized()
            update_animation_effects(Input.get_axis("ui_left", "ui_right"))
            spawn_shockwave()
            start_dash_freeze(0.1)
            ghost_count = 0
            
            create_ghost_timer(0.1001)
            create_ghost_timer(0.17)
            create_ghost_timer(0.24)

            print("Dash Start!")
        State.DOWN:
            tail.pos.y += 2.0
            anim.play("down")
            print("Down!")
        State.IDLE:
            if(current_state == State.DOWN):
                anim.play("up")
            elif(current_state == State.DASH):
                anim.play("roll_after")
            else: anim.play("idle")
            print("Idle!")
        State.RUN:
            print("Run!")
            anim.play("run")
        State.JUMP:
            anim.play("roll_before")
            on_floor = false
            $JumpDust.restart()
            $JumpDust.emitting = true
            print("Jump!")
        State.FALL:
            if current_state == State.RUN or current_state == State.IDLE:
                anim.play("roll_before")
            print("Fall!")

    current_state = new_state

func handle_physics(input_dir, delta):
    if is_frozen:
        velocity = Vector2.ZERO
        return
    if current_state == State.DASH:
        dash_timer -= delta
        velocity = dash_direction * dash_speed 
        return 
        
    if not on_floor:
        if(abs(velocity.y) < 40):
            velocity.y += gravity * delta * 0.5
        else:
            velocity.y += gravity * delta
    
    if current_state == State.DOWN:
        velocity.x = 0
        return
    if input_dir != 0:
        velocity.x = move_toward(velocity.x, input_dir * speed, acceleration * delta)
    else:
        if on_floor:
            velocity.x = move_toward(velocity.x, 0, friction * delta)
        else:
            velocity.x = move_toward(velocity.x, 0, air_friction * delta)
    
    if(velocity.y > max_fall):
        velocity.y = max_fall

func update_animation_effects(input_dir):
    if current_state == State.DASH:
        return
    
    if input_dir < 0:
        if visual.scale.x == 1:
            $head.position.x -= 4
        visual.scale.x = -1
    elif input_dir > 0:
        if visual.scale.x == -1:
            $head.position.x += 4
        visual.scale.x = 1

func apply_state_transitions(input_dir):
    if anim.current_animation == "roll" or anim.current_animation == "roll_after" or anim.current_animation == "roll_before": 
        if not tail.is_rolling:
            tail.start_rolling()
    else:
        tail.stop_rolling()
    if on_floor and current_state != State.DASH:
        can_dash = true
    if Input.is_action_just_pressed("dash") and can_dash and current_state != State.DASH:
        change_state(State.DASH)
        return
    match current_state:
        State.DASH:
            if dash_timer <= 0:
                if on_floor:
                    change_state(State.IDLE if input_dir == 0 else State.RUN)
                else:
                    change_state(State.FALL)
        State.IDLE:
            if not on_floor: 
                change_state(State.FALL)
            elif Input.is_action_pressed("down"): 
                change_state(State.DOWN)
            elif input_dir != 0: 
                change_state(State.RUN)
            elif Input.is_action_just_pressed("jump"):
                change_state(State.JUMP)
                
        State.RUN:
            if not on_floor: 
                change_state(State.FALL)
            elif Input.is_action_pressed("down"):
                change_state(State.DOWN)
            elif input_dir == 0: 
                change_state(State.IDLE)
            elif Input.is_action_just_pressed("jump"): 
                change_state(State.JUMP)
                
        State.DOWN:
            if not Input.is_action_pressed("down"):
                change_state(State.IDLE)
            elif not on_floor:
                change_state(State.FALL)
            elif Input.is_action_just_pressed("jump"):
                change_state(State.JUMP)

        State.JUMP:
            if velocity.y > 0: change_state(State.FALL)
            elif on_floor: change_state(State.IDLE)
                
        State.FALL:
            if on_floor:
                if Input.is_action_pressed("down"):
                    change_state(State.DOWN)
                else:
                    change_state(State.IDLE if input_dir == 0 else State.RUN)

func handle_jump(delta):
    if(is_frozen or room_frozen): return
    if on_floor and Input.is_action_just_pressed("jump"):
        if(current_state == State.DASH and dash_direction.x != 0):
            velocity.y = jump_velocity - 60
        else: velocity.y = jump_velocity
        current_jump_timer = jump_max_time
        change_state(State.JUMP)
        if ghost_count >= 2:
            can_dash = true
        is_jumping = true
    
    if Input.is_action_pressed("jump") and is_jumping:
        if current_jump_timer > 0:
            velocity.y += jump_hold_force * min(delta, current_jump_timer)
            current_jump_timer -= delta
        else:
            is_jumping = false
    if Input.is_action_just_released("jump"):
        is_jumping = false
        current_jump_timer = 0