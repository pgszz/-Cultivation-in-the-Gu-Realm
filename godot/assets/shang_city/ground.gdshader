shader_type canvas_item;
render_mode unshaded;

uniform sampler2D paving : repeat_enable, filter_linear_mipmap;
uniform sampler2D earth : repeat_enable, filter_linear_mipmap;
uniform sampler2D courtyard : repeat_enable, filter_linear_mipmap;
uniform sampler2D arena_floor : repeat_enable, filter_linear_mipmap;

float area(vec2 p, vec2 low, vec2 high, float feather) {
	vec2 outside = max(low-p,p-high);
	return 1.0-smoothstep(-feather,feather,max(outside.x,outside.y));
}

void fragment() {
	vec2 p=UV*vec2(2000.0,1400.0);
	vec3 soil=texture(earth,p/460.0).rgb*vec3(0.78,0.84,0.84);
	vec3 brick=texture(courtyard,p/380.0).rgb;
	vec3 street=texture(paving,p/240.0).rgb*vec3(0.96,1.0,1.02);
	vec3 ring=texture(arena_floor,p/300.0).rgb*0.9;
	float yards=max(area(p,vec2(220,370),vec2(610,750),10.0),area(p,vec2(620,330),vec2(970,620),10.0));
	yards=max(yards,area(p,vec2(220,760),vec2(610,1100),12.0));
	yards=max(yards,area(p,vec2(620,730),vec2(950,1030),12.0));
	float roads=area(p,vec2(930,340),vec2(1060,1350),6.0);
	roads=max(roads,area(p,vec2(90,600),vec2(1900,720),6.0));
	roads=max(roads,area(p,vec2(90,1050),vec2(1900,1170),6.0));
	roads=max(roads,area(p,vec2(370,610),vec2(490,1120),6.0));
	roads=max(roads,area(p,vec2(740,500),vec2(860,1120),6.0));
	roads=max(roads,area(p,vec2(1080,405),vec2(1810,520),6.0));
	vec3 ground=mix(soil,brick,yards);
	ground=mix(ground,street,roads);
	float field=area(p,vec2(1080,530),vec2(1820,990),1.5);
	ground=mix(ground,ring,field);
	// Low-frequency wear keeps broad surfaces legible and avoids repeated dark squares.
	float wear=sin(p.x*0.011+sin(p.y*0.006))*sin(p.y*0.009);
	ground*=0.98+wear*0.025;
	COLOR=vec4(ground,1.0);
}
