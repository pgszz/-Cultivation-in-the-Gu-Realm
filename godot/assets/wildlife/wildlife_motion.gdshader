shader_type canvas_item;

// Deform a subdivided illustration; all time comes from the paused game clock.
uniform vec4 leg_a;
uniform vec4 leg_b;
uniform vec4 leg_c;
uniform vec4 leg_d;
uniform vec4 leg_angles = vec4(0.0);
uniform float leg_width = 0.075;
uniform vec2 head_pivot = vec2(0.7, 0.46);
uniform float head_angle = 0.0;
uniform float tail_angle = 0.0;
uniform float ear_sway = 0.0;
uniform float wing_lift = 0.0;
uniform float hit_flash = 0.0;

vec2 turn(vec2 point, vec2 pivot, float angle) {
	float c = cos(angle);
	float s = sin(angle);
	vec2 v = point - pivot;
	return pivot + vec2(v.x*c-v.y*s, v.x*s+v.y*c);
}

float limb_weight(vec2 uv, vec4 limb) {
	if (limb.w < 0.01) { return 0.0; }
	float along = clamp((uv.y-limb.y) / max(0.08,limb.w-limb.y),0.0,1.0);
	float axis_x = mix(limb.x,limb.z,along);
	return smoothstep(0.0,0.35,along) * (1.0-smoothstep(leg_width*0.45,leg_width,abs(uv.x-axis_x)));
}

void vertex() {
	vec2 uv = UV;
	vec4 weights = vec4(limb_weight(uv,leg_a),limb_weight(uv,leg_b),limb_weight(uv,leg_c),limb_weight(uv,leg_d));
	vec2 limb_shift = (turn(uv,leg_a.xy,leg_angles.x)-uv)*weights.x;
	limb_shift += (turn(uv,leg_b.xy,leg_angles.y)-uv)*weights.y;
	limb_shift += (turn(uv,leg_c.xy,leg_angles.z)-uv)*weights.z;
	limb_shift += (turn(uv,leg_d.xy,leg_angles.w)-uv)*weights.w;
	VERTEX += limb_shift / max(1.0,dot(weights,vec4(1.0)));
	float head = smoothstep(head_pivot.x-0.12,head_pivot.x+0.08,uv.x) * (1.0-smoothstep(head_pivot.y,head_pivot.y+0.2,uv.y));
	VERTEX += (turn(uv,head_pivot,head_angle)-uv)*head;
	float tail = (1.0-smoothstep(0.16,0.35,uv.x))*smoothstep(0.25,0.5,uv.y);
	VERTEX += (turn(uv,vec2(0.3,0.5),tail_angle)-uv)*tail;
	VERTEX.x += ear_sway * (1.0-smoothstep(0.05,0.34,uv.y))*smoothstep(0.45,0.65,uv.x);
	float wing = max(0.0,1.0-length((uv-vec2(0.62,0.56))/vec2(0.22,0.22)));
	VERTEX.y -= wing*wing_lift;
}

void fragment() {
	COLOR.rgb = mix(COLOR.rgb,vec3(1.0,0.68,0.52),hit_flash*0.65);
}
