shader_type canvas_item;

uniform vec4 apron_color : source_color = vec4(0.251, 0.518, 0.314, 1.0); // #408450 default
uniform vec4 hair_color : source_color = vec4(0.071, 0.133, 0.188, 1.0); // #122230 default
uniform vec4 skin_color : source_color = vec4(0.851, 0.525, 0.365, 1.0); // #d9865d default
uniform vec4 skin_shadow_color : source_color = vec4(0.624, 0.267, 0.267, 1.0); // #9f4444 default

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float tolerance = 0.01;

	// Apron color swap (#408450)
	if (distance(tex_color.rgb, vec3(0.251, 0.518, 0.314)) < tolerance) {
		COLOR = vec4(apron_color.rgb, tex_color.a);
	}
	// Hair color swap (#122230)
	else if (distance(tex_color.rgb, vec3(0.071, 0.133, 0.188)) < tolerance) {
		COLOR = vec4(hair_color.rgb, tex_color.a);
	}
	// Skin color swap (#d9865d)
	else if (distance(tex_color.rgb, vec3(0.851, 0.525, 0.365)) < tolerance) {
		COLOR = vec4(skin_color.rgb, tex_color.a);
	}
	// Skin shadow color swap (#9f4444)
	else if (distance(tex_color.rgb, vec3(0.624, 0.267, 0.267)) < tolerance) {
		COLOR = vec4(skin_shadow_color.rgb, tex_color.a);
	}
	else {
		COLOR = tex_color;
	}
}
