shader_type canvas_item;

// ... [此处省略前部变量声明，保持不变] ...
uniform sampler2D noise_texture : repeat_enable, filter_nearest;
uniform vec2 pixel_resolution = vec2(384.0, 216.0);
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.45;
uniform float band_top : hint_range(0.0, 1.0) = 0.2;
uniform float band_bottom : hint_range(0.0, 1.0) = 0.8;
uniform vec2 scroll_speed = vec2(0.03, 0.005);
uniform vec4 color_highlight : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_midtone : source_color = vec4(0.83, 0.85, 0.9, 1.0);
uniform vec4 color_shadow : source_color = vec4(0.6, 0.65, 0.75, 1.0);
uniform float time_of_day = 0.0;
uniform vec2 sun_screen_pos = vec2(0.5, 0.5);

void fragment() {
    vec2 pixel_uv = floor(UV * pixel_resolution) / pixel_resolution;
    vec2 pixel_screen_uv = floor(SCREEN_UV * pixel_resolution) / pixel_resolution;

    vec2 motion = pixel_uv + (TIME * scroll_speed);
    float noise_val = texture(noise_texture, motion).r;
    float vertical_mask = smoothstep(band_top, band_top + 0.15, pixel_uv.y) * smoothstep(band_bottom, band_bottom - 0.15, pixel_uv.y);
    float density = noise_val * vertical_mask;

    if (density < cloud_coverage) discard;

    float screen_height = 1.0 - pixel_screen_uv.y;

    // 色彩定义 (维持之前的红橙基调)
    vec3 glow_low = mix(vec3(0.75, 0.04, 0.04), vec3(1.00, 0.16, 0.00), time_of_day * 1.2);
    vec3 glow_mid = mix(vec3(1.00, 0.27, 0.00), vec3(1.00, 0.55, 0.05), time_of_day);
    vec3 glow_high = mix(vec3(1.00, 0.25, 0.44), vec3(0.72, 0.30, 1.00), time_of_day);

    float w_mid = smoothstep(0.20, 0.40, screen_height);
    float w_high = smoothstep(0.55, 0.75, screen_height);
    vec3 final_dawn_color = mix(glow_low, glow_mid, w_mid);
    final_dawn_color = mix(final_dawn_color, glow_high, w_high);

    // =========================================================================
    // 【核心修复】取消硬性的 smoothstep 截断，改为柔和的指数衰减
    // =========================================================================
    // 增加拉伸权重，让横向范围更广
    vec2 stretch_factor = vec2(0.35, 1.0);
    float dist_to_sun = distance(pixel_screen_uv * stretch_factor, sun_screen_pos * stretch_factor);

    // 使用 exp 或 pow 实现非线性的自然消退，避免椭圆轮廓出现
    // 0.8 是强度基数，1.8 是衰减指数，数值越大衰减越快（边缘越柔和）
    float sun_influence = clamp(1.0 - (dist_to_sun * 1.5), 0.0, 1.0);
    sun_influence = pow(sun_influence, 2.5);

    float day_phase_weight = smoothstep(0.18, 0.38, time_of_day) * (1.0 - smoothstep(0.48, 0.78, time_of_day));
    float glow_strength = sun_influence * day_phase_weight;

    // ... [后半部分色阶逻辑保持不变，确保渲染一致性] ...
    vec3 sky_top = mix(vec3(0.04, 0.04, 0.12), vec3(0.3, 0.5, 0.85), time_of_day);
    vec3 sky_bottom = mix(vec3(0.15, 0.05, 0.15), vec3(0.85, 0.6, 0.35), time_of_day);
    vec3 bg_sky_color = mix(sky_bottom, sky_top, screen_height);

    vec3 shadow_rgb = mix(color_shadow.rgb, bg_sky_color * 0.5, 0.4);
    vec3 midtone_rgb = color_midtone.rgb;
    vec3 highlight_rgb = color_highlight.rgb;

    if (glow_strength > 0.1) {
        shadow_rgb = mix(shadow_rgb, midtone_rgb, glow_strength * 0.7);
        midtone_rgb = mix(midtone_rgb, highlight_rgb, glow_strength * 0.5);
    }

    float range = 1.0 - cloud_coverage;
    float t1 = cloud_coverage + range * 0.25;
    float t2 = cloud_coverage + range * 0.65;

    vec3 base_rgb = (density < t1) ? shadow_rgb : (density < t2) ? midtone_rgb : highlight_rgb;

    vec3 burned_rgb = mix(base_rgb, base_rgb * final_dawn_color * 1.8, glow_strength);
    vec3 final_rgb = mix(base_rgb, burned_rgb, mix(0.2, 1.0, glow_strength));

    if (density < t2 && glow_strength > 0.01) {
        final_rgb = mix(final_rgb, final_dawn_color * 1.4, glow_strength * 0.6);
    }

    COLOR = vec4(final_rgb, 1.0);
}