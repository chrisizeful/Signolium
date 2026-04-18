shader_type canvas_item;

uniform sampler2D palette : filter_nearest;
uniform float aspect_ratio = 1.0;
uniform float density : hint_range(0.0, 3.0, 0.0001) = 1.3;
uniform int layer_parascale : hint_range(0, 5, 1) = 4;
uniform vec2 star_speed = vec2(0.0);
uniform vec2 star_wave = vec2(0.0);
uniform float star_size : hint_range(0.0, 100.0, 0.01) = 3.0;
uniform float star_rotate_speed : hint_range(-3.0, 3.0) = 0.5;
uniform float twinkle_effect : hint_range(0.0, 1.0, 0.01) = 0.6;
uniform float twinkle_speed : hint_range(0.0, 100.0, 0.01) = 0.3;
uniform float pixelate_count = 1000.0;

float one_div_x(float x) {
	return (abs(x) < 0.0001) ? 1.0 : (1.0/x);
}

float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43759.5453123);
}

vec3 snap_to_palette(vec3 color) {
	int palette_size = textureSize(palette, 0).x;
	float best_dist = 1e10;
	vec3 best_color = vec3(0.0);
	for (int i = 0; i < palette_size; i++) {
		vec3 pc = texture(palette, vec2((float(i) + 0.5) / float(palette_size), 0.5)).rgb;
		float d = distance(color, pc);
		if (d < best_dist) {
			best_dist = d;
			best_color = pc;
		}
	}
	return best_color;
}

void fragment() {
	vec3 bg = texture(palette, vec2(0.5 / float(textureSize(palette, 0).x), 0.5)).rgb;
	vec3 color = bg;

	vec2 st = round(UV * pixelate_count) / pixelate_count;
	st.x *= aspect_ratio;
	vec2 cuv = (st - 0.5) * 2.0;

	for (int layer = 0; layer < layer_parascale; layer++) {
		float layer_scale = exp(float(layer + 1) * density);
		vec2 layer_speed = vec2(star_speed.x, star_speed.y) * (1.0 + float(layer) * 0.3);
		float layer_size = star_size * (1.0 - float(layer) * 0.2);

		vec2 layer_st = st * layer_scale;
		vec2 cuv_st = cuv;

		vec2 time_offset = TIME * layer_speed;
		layer_st -= time_offset;

		vec2 grid_st = fract(layer_st);
		vec2 grid_id = floor(layer_st);

		float rand_seed = random(grid_id);

		vec2 snow_pos = vec2(
			0.5 + (0.3 * sin((rand_seed * 6.28) + (TIME * star_wave.x))),
			0.5 + (0.2 * cos((rand_seed * 12.56) + (TIME * star_wave.y)))
		);

		float dist = distance(grid_st, snow_pos);
		float snow_size = layer_size * 0.01 * (0.5 + 0.5 * rand_seed);
		float brightness = 1.0 - (float(layer) * 0.3);

		float m = exp((-dist * dist) / (snow_size * snow_size));

		vec2 fst = cuv_st - ((grid_id + snow_pos + time_offset) / layer_scale - 0.5) * 2.0;
		float theta = atan(fst.y, fst.x) + TIME * star_rotate_speed;
		float r = length(fst);
		fst = vec2(r * cos(theta), r * sin(theta));

		float f = 0.8 - (dist * 42.0);
		float inv_bw = one_div_x(fst.x * PI / (snow_size * f));
		float inv_bh = one_div_x(fst.y * PI / (snow_size * f));
		float snowflake = m * 0.5 * (inv_bw * inv_bw * inv_bh * inv_bh + 1.0);

		float twinkle = (1.0 - twinkle_effect) + twinkle_effect * (sin(rand_seed * 100.0 + TIME * twinkle_speed) * cos(rand_seed * 120.0 + TIME * (twinkle_speed + 2.0)));
		snowflake *= twinkle;

		vec3 color_type = vec3(random(grid_id - 3.0), random(grid_id + 7.0), random(grid_id + 5.0));

		color = max(color + (snowflake * brightness) * color_type, color);
	}

	color = snap_to_palette(color);
	COLOR = vec4(color, 1.0);
}
