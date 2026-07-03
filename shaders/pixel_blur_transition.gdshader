shader_type canvas_item;
render_mode unshaded, blend_mix;

// 转场进度：0.0 为完全清晰，1.0 为极度像素化
uniform float blur_amount : hint_range(0.0, 1.0) = 0.0;

// 最大像素块尺寸（单位：屏幕像素）。数值越大，转场到 1.0 时格子越大
uniform float max_pixel_size = 64.0;

// Godot 4 正确获取屏幕纹理的写法，filter_nearest 确保像素边缘清晰锐利
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
	vec2 uv = SCREEN_UV;

	// 1. 动态计算当前的像素块大小（从 1 像素渐变到最大像素）
	// 当 blur_amount 为 0 时，大小为 1.0 像素（即完全清晰的原图）
	float current_block_size = mix(1.0, max_pixel_size, blur_amount);

	// 2. 利用内置的 SCREEN_PIXEL_SIZE 逆推出屏幕的实际分辨率
	vec2 screen_res = 1.0 / SCREEN_PIXEL_SIZE;

	// 3. 计算当前分辨率下，全屏可以横向/纵向切分成多少个格子
	vec2 grid_size = screen_res / current_block_size;

	// 4. 马赛克核心算法：阶梯化 UV 坐标，不使用 mix 混合，彻底避免除零和重影
	vec2 pixelated_uv = floor(uv * grid_size) / grid_size;

	// 5. 输出颜色
	COLOR = texture(screen_texture, pixelated_uv);
}