//Varyings//
varying vec2 oldtexcoord;
varying vec2 texcoord;
varying vec3 dpos;

#ifdef FSH
//Uniforms//
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform sampler2D shadowcolor0, shadowcolor1;

//Other random things
vec3[50] lightcols = vec3[50](
	vec3(TORCH_COL_R, TORCH_COL_G, TORCH_COL_B),//torch
	vec3(REDSTONE_TORCH_COL_R, REDSTONE_TORCH_COL_G, REDSTONE_TORCH_COL_B),//redstone_torch
	vec3(SOUL_TORCH_COL_R, SOUL_TORCH_COL_G, SOUL_TORCH_COL_B),//soul_torch
	vec3(LANTERN_COL_R, LANTERN_COL_G, LANTERN_COL_B),//lantern
	vec3(SOUL_LANTERN_COL_R, SOUL_LANTERN_COL_G, SOUL_LANTERN_COL_B),//soul_lantern
	vec3(FIRE_COL_R, FIRE_COL_G, FIRE_COL_B) * 0.85,//campfire
	vec3(SOUL_FIRE_COL_R, SOUL_FIRE_COL_G, SOUL_FIRE_COL_B) * 0.85,//soul_campfire
	vec3(REDSTONE_TORCH_COL_R, REDSTONE_TORCH_COL_G, REDSTONE_TORCH_COL_B),//redstone_wall_torch
	vec3(TORCH_COL_R, TORCH_COL_G, TORCH_COL_B),//wall_torch
	vec3(SOUL_TORCH_COL_R, SOUL_TORCH_COL_G, SOUL_TORCH_COL_B),//soul_wall_torch
	vec3(GLOWSTONE_COL_R, GLOWSTONE_COL_G, GLOWSTONE_COL_B),//glowstone
	vec3(LAVA_COL_R, LAVA_COL_G, LAVA_COL_B),//lava
	vec3(FIRE_COL_R, FIRE_COL_G, FIRE_COL_B),//fire
	vec3(NETHERP_COL_R, NETHERP_COL_G, NETHERP_COL_B),//nether_portal
	vec3(SOUL_FIRE_COL_R, SOUL_FIRE_COL_G, SOUL_FIRE_COL_B),//soul_fire
	vec3(SHROOMLIGHT_COL_R, SHROOMLIGHT_COL_G, SHROOMLIGHT_COL_B),//shroomlight
	vec3(MAGMA_COL_R, MAGMA_COL_G, MAGMA_COL_B),//magma_block
	vec3(SEA_LANTERN_COL_R, SEA_LANTERN_COL_G, SEA_LANTERN_COL_B),//sea_lantern
	vec3(FURNACE_COL_R, FURNACE_COL_G, FURNACE_COL_B),//lit_furnace
	vec3(BEACON_COL_R, BEACON_COL_G, BEACON_COL_B),//beacon
	vec3(END_PORTAL_COL_R, END_PORTAL_COL_G, END_PORTAL_COL_B),//end_portals
	vec3(CONDUIT_COL_R, CONDUIT_COL_G, CONDUIT_COL_B),//conduit
	vec3(REDSTONE_LAMP_COL_R, REDSTONE_LAMP_COL_G, REDSTONE_LAMP_COL_B),//redstone_lamp
	vec3(RESPAWN_ANCHOR_COL_R, RESPAWN_ANCHOR_COL_G, RESPAWN_ANCHOR_COL_B) * 0.25,
	vec3(RESPAWN_ANCHOR_COL_R, RESPAWN_ANCHOR_COL_G, RESPAWN_ANCHOR_COL_B) * 0.5,
	vec3(RESPAWN_ANCHOR_COL_R, RESPAWN_ANCHOR_COL_G, RESPAWN_ANCHOR_COL_B) * 0.75,
	vec3(RESPAWN_ANCHOR_COL_R, RESPAWN_ANCHOR_COL_G, RESPAWN_ANCHOR_COL_B),//respawn_anchor
	vec3(JACKOLANTERN_COL_R, JACKOLANTERN_COL_G, JACKOLANTERN_COL_B),//jack_o_lantern
	vec3(SEA_PICKLE_COL_R, SEA_PICKLE_COL_G, SEA_PICKLE_COL_B) * 0.25,
	vec3(SEA_PICKLE_COL_R, SEA_PICKLE_COL_G, SEA_PICKLE_COL_B) * 0.5,
	vec3(SEA_PICKLE_COL_R, SEA_PICKLE_COL_G, SEA_PICKLE_COL_B) * 0.75,
	vec3(SEA_PICKLE_COL_R, SEA_PICKLE_COL_G, SEA_PICKLE_COL_B), // sea_pickle
	vec3(END_ROD_COL_R, END_ROD_COL_G, END_ROD_COL_B),//end_rod
	vec3(CRYING_OBSIDIAN_COL_R, CRYING_OBSIDIAN_COL_G, CRYING_OBSIDIAN_COL_B),//crying_obsidian
	vec3(REDSTONE_COL_R, REDSTONE_COL_G, REDSTONE_COL_B) * 0.5,//redstone_ore:lit=true
	#ifdef EMISSIVE_ORES
		vec3(LAPIS_COL_R, LAVA_COL_G, LAPIS_COL_B) * 0.3,//lapis_ore
		vec3(DIAMOND_COL_R, DIAMOND_COL_G, DIAMOND_COL_B) * 0.4,//diamond_ore
		vec3(EMERALD_COL_R, EMERALD_COL_G, EMERALD_COL_B) * 0.4,//emerald_ore
		vec3(GOLD_COL_R, GOLD_COL_G, GOLD_COL_B) * 0.4,//gold_ore
		vec3(IRON_COL_R, IRON_COL_G, IRON_COL_B) * 0.4,//iron_ore
		vec3(REDSTONE_COL_R, REDSTONE_COL_G, REDSTONE_COL_B) * 0.2,//redstone_ore:lit=false
	#else
		vec3(0),
		vec3(0),
		vec3(0),
		vec3(0),
		vec3(0),
		vec3(0),
	#endif
	#ifdef GLOWING_EMERALD_BLOCK
		vec3(EMERALD_COL_R, EMERALD_COL_G, EMERALD_COL_B),//emerald_block
	#else
		vec3(0),
	#endif
	#ifdef GLOWING_REDSTONE_BLOCK
		vec3(REDSTONE_COL_R, REDSTONE_COL_G, REDSTONE_COL_B),//redstone_block
	#else
		vec3(0),
	#endif
	#ifdef GLOWING_LAPIS_BLOCK
		vec3(LAPIS_COL_R, LAPIS_COL_G, LAPIS_COL_B),//lapis_block
	#else
		vec3(0),
	#endif
	vec3(0),
	vec3(0),
	vec3(0),
	vec3(0),
	vec3(0),
	vec3(0)
);

void main(){
	vec2 oldtexcoord2 = oldtexcoord;
	float wrapping = float(oldtexcoord.x > 1 - 0.125 / VXHEIGHT && dpos.y > 0.5) - float(oldtexcoord.x < 0.125 / VXHEIGHT && dpos.y < -0.5);//float(oldtexcoord.x + 0.125 / VXHEIGHT * dpos.y > 1.0) - float(oldtexcoord.x + 0.125 / VXHEIGHT * dpos.y < 0.0);
	oldtexcoord2 += vec2(0.125 / VXHEIGHT * dpos.y - wrapping, 0.125 / VXHEIGHT * wrapping);
	vec4 blockData = texture2D(shadowcolor0, oldtexcoord2);
	float ID = floor(blockData.a * 255.0 - 25.5);
	float isLight = float(ID > 49.5 && ID < 119.5);
	vec3 colMult = texture2D(shadowcolor0, oldtexcoord2).rgb;
	colMult /= max(colMult.r, max(colMult.g, colMult.b));
	wrapping = float(oldtexcoord2.x + 0.125 / VXHEIGHT > 1.0) - float(oldtexcoord.x - 0.125 / VXHEIGHT < 0.0);
	vec2 pos0 = oldtexcoord2 - vec2(1.0 / shadowMapResolution, 0);
	vec2 pos1 = oldtexcoord2 - vec2(0, 1.0 / shadowMapResolution);
	vec2 pos2 = oldtexcoord2 - vec2(0.125 / VXHEIGHT - float(wrapping < -0.5), float(wrapping < -0.5) * 0.125 / VXHEIGHT);
	vec2 pos3 = oldtexcoord2 + vec2(1.0 / shadowMapResolution, 0);
	vec2 pos4 = oldtexcoord2 + vec2(0, 1.0 / shadowMapResolution);
	vec2 pos5 = oldtexcoord2 + vec2(0.125 / VXHEIGHT - float(wrapping > 0.5), float(wrapping > 0.5) * 0.125 / VXHEIGHT);

	vec4 col0 = texture2D(shadowcolor1, pos0) * float(abs(pos0.x - 0.5) < 0.5 && abs(pos0.y - 0.5) < 0.5);
	vec4 col1 = texture2D(shadowcolor1, pos1) * float(abs(pos1.x - 0.5) < 0.5 && abs(pos1.y - 0.5) < 0.5);
	vec4 col2 = texture2D(shadowcolor1, pos2) * float(abs(pos2.x - 0.5) < 0.5 && abs(pos2.y - 0.5) < 0.5);
	vec4 col3 = texture2D(shadowcolor1, pos3) * float(abs(pos3.x - 0.5) < 0.5 && abs(pos3.y - 0.5) < 0.5);
	vec4 col4 = texture2D(shadowcolor1, pos4) * float(abs(pos4.x - 0.5) < 0.5 && abs(pos4.y - 0.5) < 0.5);
	vec4 col5 = texture2D(shadowcolor1, pos5) * float(abs(pos5.x - 0.5) < 0.5 && abs(pos5.y - 0.5) < 0.5);
	vec4 col6 = vec4(0);
	if (isLight > 0.5) col6.rgb = lightcols[int(ID - 49.5)] / 255.0;

	col0.a = max(max(col0.r, max(col0.g, col0.b)) * float(abs(col0.a - 0.75) > 0.1), 0.0001);
	col1.a = max(max(col1.r, max(col1.g, col1.b)) * float(abs(col1.a - 0.75) > 0.1 && abs(col1.a - 0.3) > 0.1), 0.0001);
	col2.a = max(max(col2.r, max(col2.g, col2.b)) * float(abs(col2.a - 0.75) > 0.1), 0.0001);
	col3.a = max(max(col3.r, max(col3.g, col3.b)) * float(abs(col3.a - 0.75) > 0.1), 0.0001);
	col4.a = max(max(col4.r, max(col4.g, col4.b)) * float(abs(col4.a - 0.75) > 0.1 && abs(col4.a - 0.5) > 0.1), 0.0001);
	col5.a = max(max(col5.r, max(col5.g, col5.b)) * float(abs(col5.a - 0.75) > 0.1), 0.0001);
	col6.a = max(max(col6.r, max(col6.g, col6.b)), 0.0001);

	col0.rgb /= col0.a;
	col1.rgb /= col1.a;
	col2.rgb /= col2.a;
	col3.rgb /= col3.a;
	col4.rgb /= col4.a;
	col5.rgb /= col5.a;
	col6.rgb /= col6.a;

	col0.a = max(col0.a * 0.85 - 0.03, 0.0);
	col1.a = max(col1.a * 0.85 - 0.03, 0.0);
	col2.a = max(col2.a * 0.85 - 0.03, 0.0);
	col3.a = max(col3.a * 0.85 - 0.03, 0.0);
	col4.a = max(col4.a * 0.85 - 0.03, 0.0);
	col5.a = max(col5.a * 0.85 - 0.03, 0.0);
	//col6.a = max(col6.a * 0.95 - 0.03, 0.0);

	float maxAlpha = max(max(col0.a, max(col1.a, col2.a)), max(max(col3.a, col4.a), max(col5.a, col6.a)));
	vec4 col = vec4(col0.rgb * max(1 - 5 * (maxAlpha - col0.a), 0.0) + 
					col1.rgb * max(1 - 5 * (maxAlpha - col1.a), 0.0) + 
					col2.rgb * max(1 - 5 * (maxAlpha - col2.a), 0.0) + 
					col3.rgb * max(1 - 5 * (maxAlpha - col3.a), 0.0) + 
					col4.rgb * max(1 - 5 * (maxAlpha - col4.a), 0.0) + 
					col5.rgb * max(1 - 5 * (maxAlpha - col5.a), 0.0) + 
					col6.rgb * 4 * col6.a, 1.0);
	col.rgb /= max(max(0.0001, col.r), max(col.g, col.b));
	col.rgb *= maxAlpha;
	if (ID > 119.5)	col.rgb *= (0.5 * colMult + vec3(0.5));
	//col = texture2D(shadowcolor1, oldtexcoord2);
	col.a = 1.0 - 0.25 * float(ID == 1) - 0.5 * float(ID == 5) - 0.7 * float(ID == 6);
	/*DRAWBUFFERS:01*/
	gl_FragData[0] = blockData;
	gl_FragData[1] = col;
}
#endif

#ifdef VSH
//Uniforms//
uniform vec3 cameraPosition, previousCameraPosition;
uniform mat4 shadowModelView, shadowModelViewInverse;
uniform mat4 shadowProjection, shadowProjectionInverse;

void main(){
	gl_Position = ftransform();
	float vxDist = 0.125 * shadowMapResolution / VXHEIGHT;
	dpos = floor(cameraPosition) - floor(previousCameraPosition);
	oldtexcoord = gl_Position.xy + 2 * dpos.xz / shadowMapResolution;
	float tempX = oldtexcoord.x;
	oldtexcoord = oldtexcoord * 0.5 + vec2(0.5);
	texcoord = gl_Position.xy * 0.5 + vec2(0.5);
}
#endif