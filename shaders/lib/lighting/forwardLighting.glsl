uniform sampler2D shadowcolor1;

#include "/lib/vx/voxelPos.glsl"

#if (defined OVERWORLD || defined END || defined SEVEN) && defined SHADOWS
	uniform sampler2D shadowcolor0;
	#include "/lib/vx/getShadowData.glsl"
	
	vec3 DistortShadow(inout vec3 worldPos, float distortFactor){
		worldPos.xy /= distortFactor;
		worldPos.z *= 0.2;
		return worldPos * 0.5 + 0.5;
	}
#endif

#if (defined WATER_CAUSTICS || defined SHADOW_COLOR) && defined OVERWORLD && !defined GBUFFERS_WATER
	#if defined PROJECTED_CAUSTICS || defined SHADOW_COLOR
		uniform sampler2DShadow shadowtex1;
	#endif

	#include "/lib/lighting/caustics.glsl"
#endif

float GetFakeShadow(float skyLight) {
	float fakeShadow = 0.0;

	#ifndef END
		if (isEyeInWater == 0) skyLight = pow(skyLight, 30.0);
		fakeShadow = skyLight;
	#else
		#ifdef SHADOWS
			fakeShadow = 1.0;
		#else
			fakeShadow = 0.0;
		#endif
	#endif

	return fakeShadow;
}

void GetLighting(inout vec3 albedo, inout float shadow, inout float fakeShadow, vec3 viewPos, float lViewPos, vec3 worldPos,
                 vec2 lightmap, float smoothLighting, float NdotL, float quarterNdotU,
                 float parallaxShadow, float emissive, float subsurface, float mat, float leaves, float scattering, float materialAO) {
	vec3 voxelSpacePos = worldPos + fract(cameraPosition);
	vec3 worldNormal = mat3(gbufferModelViewInverse) * normal;
	vec3 worldSunVec = mat3(gbufferModelViewInverse) *sunVec;
	vec3 fullShadow = vec3(0.0);
	vec4 shadowcol = vec4(0.0);
	if (shadow == 1.0) fullShadow = vec3(1.0);
	float shadowMult = 1.0;
	float shadowTime = 1.0;

	#if defined WATER_CAUSTICS && defined OVERWORLD && !defined GBUFFERS_WATER && defined PROJECTED_CAUSTICS
		float water = 0.0;
	#endif

    #if defined OVERWORLD || defined END || defined SEVEN
		#ifdef SHADOWS
			if ((NdotL > 0.0 || subsurface + scattering > 0.001)) {
				float shadowLengthX = length(worldPos.xy);
				float shadowLengthZ = length(worldPos.yz);
				float shadowLength = shadowDistance - max(shadowLengthX, shadowLengthZ) - shadowDistance / 12.0;

				#if (defined OVERWORLD || defined SEVEN) && defined LIGHT_LEAK_FIX
					if (isEyeInWater == 0) shadowLength *= float(lightmap.y > 0.001);
				#endif

				if (shadowLength > 0.000001) {
					vec3 shadowPos = ToShadow(worldPos);
					float distb = sqrt(shadowPos.x * shadowPos.x + shadowPos.y * shadowPos.y);
					float distortFactor = distb * shadowMapBias + (1.0 - shadowMapBias);
					shadowPos = DistortShadow(shadowPos, distortFactor);

					#ifdef NORMAL_MAPPING
						float NdotLm = clamp(dot(normal, lightVec) * 1.01 - 0.01, 0.0, 1.0) * 0.99 + 0.01;
						NdotL = min(NdotL, NdotLm);
					#else
						float NdotLm = NdotL * 0.99 + 0.01;
					#endif

					float dotWorldPos = dot(worldPos.xyz, worldPos.xyz);
					
					float biasFactor = sqrt(1.0 - NdotLm * NdotLm) / NdotLm;
					float distortBias = distortFactor * shadowDistance / 256.0;
					distortBias *= 8.0 * distortBias;
					
					float bias = (distortBias * biasFactor + dotWorldPos * 0.000005 + 0.05) / shadowMapResolution;
					float offset = 1.0 / shadowMapResolution;

					worldSunVec *= 2 * float(worldSunVec.y > 0.0) - 1;
					shadowcol = GetShadow(voxelSpacePos + 0.01 * normalize(worldSunVec), worldSunVec);
					shadow = float(max(shadowcol.r, max(shadowcol.g, shadowcol.b)) > 0.51);
					
					#if defined WATER_CAUSTICS && defined OVERWORLD && !defined GBUFFERS_WATER && defined PROJECTED_CAUSTICS
						if (isEyeInWater == 0) {
							if (shadow < 0.999) {
								water = texture2D(shadowcolor0, shadowPos.st).r
									* shadow2D(shadowtex1, vec3(shadowPos.st, shadowPos.z)).x;
								#ifdef SHADOW_FILTER
									shadowPos.z -= bias * shadowMapResolution / 2048.0;
									for(int i = 0; i < 8; i++) {
										vec2 shadowOffset = 0.002 * shadowoffsets[i];
										water += texture2D(shadowcolor0, shadowOffset + shadowPos.st).r
											* shadow2D(shadowtex1, vec3(shadowOffset + shadowPos.st, shadowPos.z)).x;
									}
									water *= 0.1;
									water *= water;
								#endif
								water *= NdotL;
							}
						}
					#endif
				} else {
					//albedo.rgb *= 0.0;
				}
				float shadowLength2 =max(abs(voxelSpacePos.x), abs(voxelSpacePos.z));
				float shadowSmooth = 8.0;
				if (shadowLength2 > 0.0625 / VXHEIGHT * shadowMapResolution && abs(voxelSpacePos.y) > 32 * pow2(VXHEIGHT)) {
					float shadowLengthDecider = max(shadowLength2 / shadowSmooth - float(abs(voxelSpacePos.y) > 32 * pow2(VXHEIGHT)), 0.0);
					float skyLightShadow = GetFakeShadow(lightmap.y);
					shadow = mix(skyLightShadow, shadow, shadowLengthDecider);
					subsurface *= mix(subsurface * 0.5, subsurface, shadowLengthDecider);
					fakeShadow = mix(1.0, fakeShadow, shadowLengthDecider);
					fakeShadow = 1.0 - fakeShadow;
					fakeShadow *= fakeShadow;
					fakeShadow = 1.0 - fakeShadow;
				}
			}
		#else
			shadow = GetFakeShadow(lightmap.y);
			shadowcol = vec4(shadow);
		#endif
		
		#if defined CLOUD_SHADOW && defined OVERWORLD
			float cloudSize = 0.000025;
			vec2 wind = vec2(frametime, 0.0) * CLOUD_SPEED * 6.0;
			float cloudShadow = texture2D(noisetex, cloudSize * (wind + (worldPos.xz + cameraPosition.xz))).r;
			cloudShadow += texture2D(noisetex, cloudSize * (vec2(1000.0) + wind + (worldPos.xz + cameraPosition.xz))).r;
			cloudShadow = clamp(cloudShadow, 0.0, 1.0);
			cloudShadow *= cloudShadow;
			cloudShadow *= cloudShadow;
			shadow *= cloudShadow;
		#endif

		#ifdef ADVANCED_MATERIALS
			#ifdef SELF_SHADOW
				shadow *= mix(1.0, parallaxShadow, NdotL);
			#endif
		#endif

		if (leaves > 0.5) {
			subsurface *= SCATTERING_LEAVES;
			#ifndef SHADOWS
				subsurface *= 0.5;
			#endif
		} else {
			subsurface *= SCATTERING_FOLIAGE;
			#ifndef SHADOWS
				subsurface *= subsurface;
				subsurface *= subsurface;
			#endif
		}
		if (subsurface == 0.0) subsurface += scattering * scattering;
		
		fullShadow = (shadowcol.rgb) * max(NdotL, subsurface * (1.0 - max(rainStrengthS, (1.0 - sunVisibility)) * 0.40)) * (1.0 - fullShadow);

		#if defined OVERWORLD && !defined TWO
			shadowMult = 1.0 * (1.0 - 0.9 * rainStrengthS);
			
			#ifdef LIGHT_JUMPING_FIX
				shadowTime = abs(sunVisibility - 0.5) * 2.0;
				shadowTime *= shadowTime;
				shadowMult *= shadowTime * shadowTime;
			#endif
			
			#ifndef LIGHT_LEAK_FIX
				ambientCol *= pow(lightmap.y, 2.5);
			#else
				if (isEyeInWater == 1) ambientCol *= pow(lightmap.y, 2.5);
			#endif
			
			vec3 lightingCol = pow(lightCol, vec3(1.0 + sunVisibility));
			#ifdef SHADOWS
				lightingCol *= (1.0 + 0.5 * leaves);
			#else
				lightingCol *= (1.0 + 0.4 * leaves);
			#endif
			vec3 shadowDecider = fullShadow * shadowMult;
			if (isEyeInWater == 1) shadowDecider *= pow(min(lightmap.y * 1.03, 1.0), 200.0);
			vec3 sceneLighting = mix(ambientCol * AMBIENT_GROUND, lightingCol * LIGHT_GROUND, shadowDecider);

			//sceneLighting *= (0.7 + 0.2 * max(vsBrightness, sunVisibility));
			
			#ifdef LIGHT_LEAK_FIX
				if (isEyeInWater == 0) sceneLighting *= pow(lightmap.y, 2.5);
			#endif
		#endif

		#ifdef END
			vec3 ambientEnd = endCol * 0.07;
			vec3 lightEnd   = endCol * 0.17;
			//vec3 sceneLighting = endCol * (0.1 * fullShadow + 0.07);
			vec3 shadowDecider = fullShadow;
			vec3 sceneLighting = mix(ambientEnd, lightEnd, shadowDecider);
			sceneLighting *= END_I * (0.7 + 0.4 * vsBrightness);
		#endif

		#ifdef TWO
			#ifndef ABYSS
				vec3 sceneLighting = vec3(0.0003, 0.0004, 0.002) * 10.0;
			#else
				vec3 sceneLighting = pow(fogColor, vec3(0.2)) * 0.125;
			#endif
		#endif
		
		#if defined SEVEN && !defined SEVEN_2
			sceneLighting = vec3(0.005, 0.006, 0.018) * 133 * (0.3 * fullShadow + 0.025);
		#endif
		#ifdef SEVEN_2
			vec3 sceneLighting = vec3(0.005, 0.006, 0.018) * 33 * (1.0 * fullShadow + 0.025);
		#endif
		#if defined SEVEN || defined SEVEN_2
			sceneLighting *= lightmap.y * lightmap.y;
		#endif
		
		#ifdef SHADOWS
			if (subsurface > 0.001) {
				float VdotL = clamp(dot(normalize(viewPos.xyz), lightVec), 0.0, 1.0);
				sceneLighting *= 5.0 * (1.0 - fakeShadow) * shadowTime * fullShadow * (1.0 + leaves) * pow(VdotL, 10.0) + 1.0;
			}
		#endif
    #else
		#ifdef NETHER
			#if MC_VERSION <= 11600
			#else
				if (quarterNdotU < 0.5625) quarterNdotU = 0.5625 + (0.4 - quarterNdotU * 0.7111111111111111);
			#endif
		
			vec3 sceneLighting = netherCol * (1 - pow(length(fogColor / 3), 0.25)) * NETHER_I * (vsBrightness*0.5 + 0.5);
		#else
			vec3 sceneLighting = vec3(0.0);
		#endif
    #endif
	
	#if !defined COMPATIBILITY_MODE && defined GBUFFERS_WATER
		if (mat > 2.98 && mat < 3.02) sceneLighting *= 0.0; // Nether Portal
	#endif


	#ifdef DYNAMIC_SHADER_LIGHT
		float handLight = min(float(heldBlockLightValue2 + heldBlockLightValue), 15.0) / 15.0;
		float handLightFactor = 1.0 - min(DYNAMIC_LIGHT_DISTANCE, lViewPos) / DYNAMIC_LIGHT_DISTANCE;
		#ifdef GBUFFERS_WATER
			handLight *= 0.9;
		#endif
		float finalHandLight = handLight * handLightFactor * 0.95;
		lightmap.x = max(finalHandLight, lightmap.x);
	#endif

	#if !defined COMPATIBILITY_MODE && defined ADVANCED_MATERIALS
		float newLightmap  = pow(lightmap.x, 10.0) * 5 + max((lightmap.x - 0.05) * 0.925, 0.0) * (vsBrightness*0.25 + 0.9);
	#else
		if (lightmap.x > 0.5) lightmap.x = smoothstep(0.0, 1.0, lightmap.x);
		float newLightmap  = pow(lightmap.x, 10.0) * 1.75 + max((lightmap.x - 0.05) * 0.925, 0.0) * (vsBrightness*0.25 + 0.9);
	#endif
	
	#ifdef BLOCKLIGHT_FLICKER
		float frametimeM = frametime * 0.5;
		newLightmap *= min(((1 - clamp(sin(fract(frametimeM*2.7) + frametimeM*3.7) - 0.75, 0.0, 0.25) * BLOCKLIGHT_FLICKER_STRENGTH)
					* max(fract(frametimeM*1.4), (1 - BLOCKLIGHT_FLICKER_STRENGTH * 0.25))) / (1.0 - BLOCKLIGHT_FLICKER_STRENGTH * 0.2)
					, 0.8) * 1.25
					* 0.8 + 0.2 * clamp((cos(fract(frametimeM*0.47) * fract(frametimeM*1.17) + fract(frametimeM*2.17))) * 1.5, 1.0 - BLOCKLIGHT_FLICKER_STRENGTH * 0.25, 1.0);
	#endif

	vec3 blockLighting = vec3(0);
	#if defined OVERWORLD || defined NETHER || defined END
	if (abs(voxelSpacePos.x) < 0.065 * shadowMapResolution / VXHEIGHT - 10 && abs(voxelSpacePos.z) < 0.065 * shadowMapResolution / VXHEIGHT - 10 && voxelSpacePos.y < 32 * pow2(VXHEIGHT)) {
		vec3[2] voxelPos0 = getVoxelPos(vec3(voxelSpacePos.x, floor(voxelSpacePos.y + 0.01) - 0.49, voxelSpacePos.z) + 0.5 * worldNormal);
		vec3 blockLightCol0 = texture2D(shadowcolor1, voxelPos0[0].xz / shadowMapResolution + vec2(0.5)).rgb;// * float(abs(voxelPos0[0].x / shadowMapResolution) < 0.5 && abs(voxelPos0[0].z / shadowMapResolution) < 0.5);
		vec3[2] voxelPos1 = getVoxelPos(vec3(voxelSpacePos.x, floor(voxelSpacePos.y + 0.01) + 0.51, voxelSpacePos.z) + 0.5 * worldNormal);
		vec3 blockLightCol1 = texture2D(shadowcolor1, voxelPos1[0].xz / shadowMapResolution + vec2(0.5)).rgb;// * float(abs(voxelPos1[0].x / shadowMapResolution) < 0.5 && abs(voxelPos1[0].z / shadowMapResolution) < 0.5);
		blockLighting = mix(blockLightCol0, blockLightCol1, fract(voxelSpacePos.y + 0.01));
		blockLighting = pow(blockLighting, vec3(1.5));
	}else{
	#endif
		blockLighting = blocklightCol * newLightmap * newLightmap;
	#if defined OVERWORLD || defined NETHER || defined END
	}
	#endif

	#ifndef MIN_LIGHT_EVERYWHERE
		float minLighting = 0.000000000001 + (MIN_LIGHT * 0.0035 * (vsBrightness*0.08 + 0.01)) * (1.0 - eBS);
	#else
		float minLighting = 0.000000000001 + (MIN_LIGHT * 0.0035 * (vsBrightness*0.08 + 0.01));
	#endif
	
	float shade = pow(quarterNdotU, SHADING_STRENGTH);

	vec3 emissiveLighting = albedo.rgb * emissive * 20.0 / shade;

    float nightVisionLighting = nightVision * 0.25;

	smoothLighting = clamp(smoothLighting, 0.0, 1.0);
	smoothLighting = pow(smoothLighting, 
						(2.0 - min(length(fullShadow * shadowMult), 1.5)) * VAO_STRENGTH
						);

	if (materialAO < 1.0) {
		smoothLighting *= pow(materialAO, max(1.0 - shadowTime * length(shadow) * NdotL - lmCoord.x, 0.0));
	}

    albedo *= sceneLighting + blockLighting + emissiveLighting + nightVisionLighting + minLighting;
	albedo *= shade * smoothLighting;

	#if defined WATER_CAUSTICS && defined OVERWORLD && !defined GBUFFERS_WATER
		#ifdef PROJECTED_CAUSTICS
		if (water > 0.0 || isEyeInWater == 1) {
		#else
		if (isEyeInWater == 1) {
		#endif
			vec3 albedoCaustic = albedo;

			float skyLightMap = lightmap.y * lightmap.y * (3.0 - 2.0 * lightmap.y);
			
			float causticfactor = (1.0 - rainStrengthS * 0.5) * (1.0 - lightmap.x * 0.8);

			vec3 causticpos = worldPos.xyz + cameraPosition.xyz;
			float caustic = getCausticWaves(causticpos * 0.75);
			vec3 causticcol = rawWaterColor.rgb / UNDERWATER_I;
			
			#ifdef PROJECTED_CAUSTICS
				if (isEyeInWater == 0) {
					//causticfactor *= (1.0 - skyLightMap * skyLightMap);
					causticfactor *= 1.0 - pow2(pow2((1.0 - skyLightMap)));
					causticfactor *= 10.0;

					causticcol *= causticcol;
					causticcol *= causticcol;
					albedoCaustic = albedo.rgb * mix(rawWaterColor.rgb * 20.0, causticcol * 1000.0, sunVisibility);
					causticcol *= 120.0;
				} else {
			#endif
					causticfactor *= (1.0 - skyLightMap * skyLightMap) * shadow * NdotL;
					causticfactor *= 0.1 + 0.9 * (1.0 - pow2(1.0 - skyLightMap));

					albedoCaustic = (albedo.rgb + albedo.rgb * rawWaterColor.rgb * 16.0) * 0.225;
					causticcol = sqrt(causticcol) * 30.0;
			#ifdef PROJECTED_CAUSTICS
				}
			#endif

			vec3 lightcaustic = caustic * causticfactor * causticcol * UNDERWATER_I;
			albedoCaustic *= 1.0 + lightcaustic;

			#ifdef PROJECTED_CAUSTICS
				if (isEyeInWater == 0) albedo = mix(albedo, albedoCaustic, water);
				else albedo = albedoCaustic;
			#else
				albedo = albedoCaustic;
			#endif
		}
	#endif

	#if defined GBUFFERS_HAND && defined HAND_BLOOM_REDUCTION
		float albedoStrength = (albedo.r + albedo.g + albedo.b) / 10.0;
		if (albedoStrength > 1.0) albedo.rgb = albedo.rgb * max(2.0 - pow(albedoStrength, 1.0), 0.34);
	#endif

	//if (water > 0.0) albedo = vec3(1.0, 0.0, 1.0);
}