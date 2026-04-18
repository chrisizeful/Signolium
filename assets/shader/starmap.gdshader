shader_type canvas_item;

uniform sampler2D noise_texture : filter_nearest;
uniform float cell_border_width : hint_range(0.0, 0.1) = 0.03;
uniform vec4 border_color : source_color = vec4(0.4, 0.6, 1.0, 0.8);
uniform vec4 highlight_color : source_color = vec4(0.3, 0.5, 1.0, 1.0);
uniform vec2 rect_size = vec2(1.0, 1.0);
uniform float circle_scale : hint_range(0.0, 1.0) = 0.5;
uniform float hovered_value = -999.0;
uniform float visited_values[64]; // Up to 64 visited sectors
uniform int visited_count = 0;
uniform vec4 visited_color : source_color = vec4(1.0, 0.8, 0.2, 1.0);

// Hash function for generating sector colors from cell value
vec3 sector_color(float cell_value) {
	float hue = fract(cell_value * 7.13 + 0.3);
	float sat = 0.4 + 0.3 * fract(cell_value * 3.71);
	float val = 0.15 + 0.2 * fract(cell_value * 5.37);
	// HSV to RGB
	vec3 c = vec3(hue, sat, val);
	vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return c.z * mix(vec3(1.0), rgb, c.y);
}

void fragment() {
	// Snap current UV to texel center for consistent sampling
	vec2 tex_size = vec2(textureSize(noise_texture, 0));
	vec2 snapped_uv = (floor(UV * tex_size) + 0.5) / tex_size;
	float cell_value = texture(noise_texture, snapped_uv).r;

	// Sample neighbors (snapped to their texel centers)
	vec2 texel = vec2(1.0) / tex_size;
	float right = texture(noise_texture, snapped_uv + vec2(texel.x, 0.0)).r;
	float up    = texture(noise_texture, snapped_uv + vec2(0.0, texel.y)).r;
	float left  = texture(noise_texture, snapped_uv - vec2(texel.x, 0.0)).r;
	float down  = texture(noise_texture, snapped_uv - vec2(0.0, texel.y)).r;

	// Border: any neighbor with a different value
	float edge = 1.0 - step(0.5,
		step(abs(cell_value - right), 0.0001) *
		step(abs(cell_value - up), 0.0001) *
		step(abs(cell_value - left), 0.0001) *
		step(abs(cell_value - down), 0.0001)
	);


	// Check if cell is visited
	bool is_visited = false;
	for (int i = 0; i < visited_count; i++) {
		if (abs(cell_value - visited_values[i]) < 0.0001) {
			is_visited = true;
			break;
		}
	}
	bool is_hovered = (cell_value == hovered_value);
	vec3 sector_fill = is_hovered ? highlight_color.rgb : (is_visited ? visited_color.rgb : vec3(0.05));

	// Blend fill color with border
	vec3 final_color = mix(sector_fill, border_color.rgb, edge * border_color.a);

	// Circular mask (pixelated, aspect-corrected)
	vec2 circle_uv = (floor(UV * tex_size) + 0.5) / tex_size;
	float aspect = rect_size.x / rect_size.y;
	vec2 center = circle_uv - vec2(0.5);
	if (aspect > 1.0) {
		center.x *= aspect;
	} else {
		center.y /= aspect;
	}
	float radius = circle_scale;
	float dist = length(center);
	float circle = step(dist, radius);

	COLOR = vec4(final_color, circle);
}
