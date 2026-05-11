shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform float force : hint_range(0.0, 1.0) = 0.02; // 扭曲强度
uniform float size : hint_range(0.0, 1.0) = 0.0;  // 扩散半径
uniform float thickness : hint_range(0.0, 0.2) = 0.1; // 环形宽度

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

void fragment() {
    // 1. 修正宽高比 (防止冲击波变椭圆)
    // 如果是屏幕后处理，可以传入屏幕比例。简单测试可以直接用 UV
    vec2 scaled_uv = (UV - center);
    // 如果画面比例不是 1:1，建议在这里乘上 SCREEN_PIXEL_SIZE 的比例
    
    float dist = length(scaled_uv);
    
    // 2. 优化 Mask 计算：使用一个更平滑的圆环
    // 只有在 size 附近的像素才会受到影响
    float mask = smoothstep(size - thickness, size, dist) * (1.0 - smoothstep(size, size + thickness, dist));
    
    // 3. 计算位移
    // 重点：使用正弦函数或平滑曲线，让扭曲有一个“往回拉”的过程，这样不会产生严重的断层
    vec2 disp_dir = normalize(UV - center);
    vec2 final_disp = disp_dir * force * mask;
    
    // 4. 采样屏幕
    // 我们减去位移量，模拟光线折射
    vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV - final_disp);
    
    // 直接输出屏幕颜色，不进行任何颜色加减
    COLOR = screen_color;
    
    // 可选：如果你想观察 mask 的范围，可以取消下面这行的注释（调试用）
    // COLOR.rgb += mask * 0.2; 
}