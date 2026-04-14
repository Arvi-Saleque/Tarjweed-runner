shader_type spatial;
render_mode depth_draw_never, cull_disabled;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture;

group_uniforms Color;
uniform vec4 surface_color : source_color = vec4(0.22, 0.58, 0.46, 0.84);
uniform vec4 depth_color : source_color = vec4(0.05, 0.15, 0.14, 0.96);
uniform vec4 foam_color : source_color = vec4(0.82, 0.94, 0.86, 0.92);
uniform vec4 highlight_color : source_color = vec4(0.62, 0.92, 0.78, 1.0);
uniform float alpha_strength : hint_range(0.0, 1.0, 0.01) = 0.88;
uniform float depth_size = 4.5;

group_uniforms Wave;
uniform float primary_scale = 0.46;
uniform float detail_scale = 1.25;
uniform vec2 primary_velocity = vec2(0.05, 0.02);
uniform vec2 detail_velocity = vec2(-0.03, 0.04);
uniform float displacement_amount = 0.10;
uniform float refraction_amount = 0.012;
uniform float highlight_amount = 0.18;

group_uniforms Foam;
uniform float edge_foam_strength = 1.15;
uniform float wave_foam_threshold = 0.64;
uniform float wave_foam_softness = 0.14;

varying vec3 world_pos;


float hash12(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}


float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}


float fbm(vec2 p) {
	float value = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		value += noise2(p) * amp;
		p = p * 2.02 + vec2(17.0, 29.0);
		amp *= 0.5;
	}
	return value;
}


vec4 sample_world_dpos(vec2 screen_uv, mat4 inv_proj_mat, mat4 inv_view_mat) {
	float depth = texture(DEPTH_TEXTURE, screen_uv).r;
	vec4 clip_pos = vec4(screen_uv * 2.0 - 1.0, depth, 1.0);
	vec4 view_pos = inv_proj_mat * clip_pos;
	view_pos /= view_pos.w;
	return inv_view_mat * view_pos;
}


float sample_wave_height(vec2 uv) {
	float primary = fbm(uv * primary_scale + TIME * primary_velocity);
	float detail = fbm(uv * detail_scale + TIME * detail_velocity);
	return primary * 0.68 + detail * 0.32;
}


void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float wave = sample_wave_height(world_pos.xz);
	VERTEX.y += (wave - 0.5) * displacement_amount;
}


void fragment() {
	float wave = sample_wave_height(world_pos.xz);
	float wave_detail = sample_wave_height(world_pos.xz + vec2(3.7, -2.9));

	vec2 screen_uv = SCREEN_UV + ((wave - 0.5) * refraction_amount);
	vec4 world_dpos = sample_world_dpos(screen_uv, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	float depth = clamp((world_dpos.y - world_pos.y + depth_size) / depth_size, 0.0, 1.0);
	depth = pow(depth, 2.4);

	float shallow = 1.0 - depth;
	float edge_foam = shallow * edge_foam_strength;
	float wave_foam = smoothstep(wave_foam_threshold - wave_foam_softness, wave_foam_threshold + wave_foam_softness, wave * wave_detail);
	float foam = clamp(max(edge_foam, wave_foam), 0.0, 1.0);

	vec3 base_color = mix(depth_color.rgb, surface_color.rgb, depth);
	base_color += highlight_color.rgb * smoothstep(0.60, 0.95, wave) * highlight_amount;

	vec3 refracted = texture(screen_texture, screen_uv).rgb;
	vec3 color = mix(refracted, base_color, 0.76);
	color = mix(color, foam_color.rgb, foam * 0.92);

	float wave_dx = sample_wave_height(world_pos.xz + vec2(0.08, 0.0)) - sample_wave_height(world_pos.xz - vec2(0.08, 0.0));
	float wave_dz = sample_wave_height(world_pos.xz + vec2(0.0, 0.08)) - sample_wave_height(world_pos.xz - vec2(0.0, 0.08));
	NORMAL = normalize(vec3(-wave_dx * 3.0, 1.0, -wave_dz * 3.0));

	ALBEDO = color;
	ROUGHNESS = mix(0.10, 0.34, foam);
	SPECULAR = 0.35;
	EMISSION = highlight_color.rgb * smoothstep(0.70, 1.0, wave) * 0.08;
	ALPHA = alpha_strength;
}
