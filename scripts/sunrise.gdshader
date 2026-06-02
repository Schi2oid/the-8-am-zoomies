shader_type canvas_item;

// 由主控脚本传进来的 0.0 ~ 1.0 的时间轴（0.0为破晓前，1.0为完全日出）
uniform float time_of_day : hint_range(0.0, 1.0) = 0.0;

// 像素风画质开关（可选）：开启后天空也会有一格一格的色带感，关闭则丝滑过渡
uniform bool pixelated = false;
uniform vec2 pixel_resolution = vec2(384.0, 216.0);

// 辅助函数：计算单列垂直方向（Y轴）的 5 种颜色之间的线性插值
vec3 sample_column(vec3 c0, vec3 c1, vec3 c2, vec3 c3, vec3 c4, float y) {
    float h = clamp(y, 0.0, 1.0) * 4.0;
    if (h < 1.0) {
        return mix(c0, c1, h);
    } else if (h < 2.0) {
        return mix(c1, c2, h - 1.0);
    } else if (h < 3.0) {
        return mix(c2, c3, h - 2.0);
    } else {
        return mix(c3, c4, h - 3.0);
    }
}

void fragment() {
    // 1. 像素化处理（如果开启）
    vec2 sky_uv = UV;
    if (pixelated) {
        sky_uv = floor(UV * pixel_resolution) / pixel_resolution;
    }

    // --- 硬编码天空颜色矩阵 (按原本色盘精确转换出的 RGB 归一化浮点数) ---

    // T0: 破晓前 (X = 0)
    vec3 c0_0 = vec3(0.039, 0.051, 0.102); // #0A0D1A
    vec3 c0_1 = vec3(0.067, 0.086, 0.180); // #11162E
    vec3 c0_2 = vec3(0.106, 0.133, 0.271); // #1B2245
    vec3 c0_3 = vec3(0.153, 0.192, 0.361); // #27315C
    vec3 c0_4 = vec3(0.235, 0.247, 0.388); // #3C3F63

    // T1: 微光初现 (X = 64)
    vec3 c1_0 = vec3(0.059, 0.078, 0.176); // #0F142D
    vec3 c1_1 = vec3(0.145, 0.110, 0.247); // #251C3F
    vec3 c1_2 = vec3(0.329, 0.125, 0.290); // #54204A
    vec3 c1_3 = vec3(0.549, 0.200, 0.290); // #8C334A
    vec3 c1_4 = vec3(0.812, 0.341, 0.294); // #CF574B

    // T2: 黄金时刻 (X = 128)
    vec3 c2_0 = vec3(0.086, 0.157, 0.322); // #162852
    vec3 c2_1 = vec3(0.157, 0.259, 0.482); // #28427B
    vec3 c2_2 = vec3(0.416, 0.290, 0.529); // #6A4A87
    vec3 c2_3 = vec3(0.839, 0.365, 0.294); // #D65D4B
    vec3 c2_4 = vec3(0.965, 0.659, 0.271); // #F6A845

    // T3: 朝霞初退 (X = 192)
    vec3 c3_0 = vec3(0.110, 0.255, 0.510); // #1C4182
    vec3 c3_1 = vec3(0.192, 0.388, 0.659); // #3163A8
    vec3 c3_2 = vec3(0.353, 0.561, 0.761); // #5A8FC2
    vec3 c3_3 = vec3(0.639, 0.753, 0.839); // #A3C0D6
    vec3 c3_4 = vec3(0.988, 0.835, 0.506); // #FCD581

    // T4: 完全日出 (X = 255)
    vec3 c4_0 = vec3(0.125, 0.322, 0.584); // #205295
    vec3 c4_1 = vec3(0.200, 0.435, 0.659); // #336FA8
    vec3 c4_2 = vec3(0.298, 0.588, 0.788); // #4C96C9
    vec3 c4_3 = vec3(0.498, 0.682, 0.796); // #7FAECB
    vec3 c4_4 = vec3(0.737, 0.886, 0.957); // #BCE2F4

    // 2. 双线性混合逻辑：根据时间轴切分 4 个跨度，动态计算左右两侧的垂直颜色
    float t = clamp(time_of_day, 0.0, 1.0) * 4.0;
    vec3 col_left;
    vec3 col_right;
    float t_factor;

    if (t < 1.0) {
        col_left  = sample_column(c0_0, c0_1, c0_2, c0_3, c0_4, sky_uv.y);
        col_right = sample_column(c1_0, c1_1, c1_2, c1_3, c1_4, sky_uv.y);
        t_factor  = t;
    } else if (t < 2.0) {
        col_left  = sample_column(c1_0, c1_1, c1_2, c1_3, c1_4, sky_uv.y);
        col_right = sample_column(c2_0, c2_1, c2_2, c2_3, c2_4, sky_uv.y);
        t_factor  = t - 1.0;
    } else if (t < 3.0) {
        col_left  = sample_column(c2_0, c2_1, c2_2, c2_3, c2_4, sky_uv.y);
        col_right = sample_column(c3_0, c3_1, c3_2, c3_3, c3_4, sky_uv.y);
        t_factor  = t - 2.0;
    } else {
        col_left  = sample_column(c3_0, c3_1, c3_2, c3_3, c3_4, sky_uv.y);
        col_right = sample_column(c4_0, c4_1, c4_2, c4_3, c4_4, sky_uv.y);
        t_factor  = clamp(t - 3.0, 0.0, 1.0);
    }

    // 3. 将左右两个关键时间点的颜色再次进行时间上的线性插值，得到最终色彩
    vec3 final_sky_color = mix(col_left, col_right, t_factor);

    COLOR = vec4(final_sky_color, 1.0);
}