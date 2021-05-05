float distx(float dist) {
	return (far * (dist - near)) / (dist * (far - near));
}

float getDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

vec4 distortShadow(vec4 shadowpos, float distortFactor) {
	shadowpos.xy *= 1.0 / distortFactor;
	shadowpos.z = shadowpos.z * 0.2;
	shadowpos = shadowpos * 0.5 + 0.5;

	return shadowpos;
}

vec4 getShadowSpace(float shadowdepth, vec2 texCoord) {
	vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, shadowdepth, 1.0) * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec4 wpos = gbufferModelViewInverse * viewPos;
	wpos = shadowModelView * wpos;
	wpos = shadowProjection * wpos;
	wpos /= wpos.w;
	
	float distb = sqrt(wpos.x * wpos.x + wpos.y * wpos.y);
	float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
	wpos = distortShadow(wpos,distortFactor);
	
	#if defined WATER_CAUSTICS && defined OVERWORLD && defined SMOKEY_WATER_LIGHTSHAFTS
		if (isEyeInWater == 1.0) {
			vec3 worldPos = ToWorld(viewPos.xyz);
			vec3 causticpos = worldPos.xyz + cameraPosition.xyz;
			float caustic = getCausticWaves(causticpos.xyz * 0.25);
			wpos.xy *= 1.0 + caustic * 0.0125;
		}
	#endif
	
	return wpos;
}

//Volumetric light from Robobo1221 (highly modified)
vec3 getVolumetricRays(float pixeldepth0, float pixeldepth1, vec3 color, float dither, vec4 viewPos) {
	vec3 vl = vec3(0.0);

	#if AA > 1
		dither = fract(dither + frameTimeCounter * 64.0);
	#endif
	
	#ifdef OVERWORLD
		#if LIGHT_SHAFT_MODE == 1 || defined END
			vec3 nViewPos = normalize(viewPos.xyz);
			vec3 lightVec = sunVec * (1.0 - 2.0 * float(timeAngle > 0.5325 && timeAngle < 0.9675));
			float cosS = dot(nViewPos, lightVec);
			float visfactor = 0.01 * (3.0 * max(rainStrengthS - isEyeInWater, 0.0) + 1.0);
			float invvisfactor = 1.0 - visfactor;

			float visibility = clamp(cosS * 0.5 + 0.5, 0.0, 1.0);
			visibility = clamp((visfactor / (1.0 - invvisfactor * visibility) - visfactor) * 1.015 / invvisfactor - 0.015, 0.0, 1.0);

			visibility = visibility * 0.14285;
		#else
			float visibility = 0.055;
			if (isEyeInWater == 1) visibility = 0.19;

			vec3 nViewPos = normalize(viewPos.xyz);
			vec3 lightVec = sunVec * (1.0 - 2.0 * float(timeAngle > 0.5325 && timeAngle < 0.9675));
			float cosS = dot(nViewPos, lightVec);

			float endurance = LIGHTSHAFT_ENDURANCE;

			#if LIGHT_SHAFT_MODE == 2
				if (isEyeInWater == 0) endurance *= min(2.0 + rainStrengthS*rainStrengthS - sunVisibility * sunVisibility, 2.0);
				if (endurance < 5.40) {
					if (endurance >= 1.0) visibility *= max((cosS + endurance) / (endurance + 1.0), 0.0);
					else visibility *= pow(max((cosS + 1.0) / 2.0, 0.0), (11.0 - endurance*10.0));
				}
			#else
				if (isEyeInWater == 0) endurance *= min(1.0 + rainStrengthS*rainStrengthS, 2.0);
				float timeBrightnessM = smoothstep(0.0, 1.0, 1.0 - pow2(1.0 - max(timeBrightness, moonBrightness)));
				if (endurance < 5.40) {
					if (endurance >= 1.0) cosS = max((cosS + endurance) / (endurance + 1.0), 0.0);
					else cosS = pow(max((cosS + 1.0) / 2.0, 0.0), (11.0 - endurance*10.0));
				}
			#endif
		#endif
		
		if (eyeAltitude < 2.0) visibility *= clamp((eyeAltitude-1.0), 0.0, 1.0);
	#endif
	
	#ifdef END
		float visibility = 0.14285;
	#endif

	if (visibility > 0.0) {
		#if LIGHT_SHAFT_MODE == 1 || defined END
			float maxDist = 192.0 * (1.5 - isEyeInWater);
		#else
			float maxDist = LIGHTSHAFT_MAX_DISTANCE * 3.0;
		#endif
		
		float depth0 = getDepth(pixeldepth0);
		float depth1 = getDepth(pixeldepth1);
		//if (isEyeInWater == 1 && depth1 > depth0) depth1 = getDepth(pixeldepth2);
		vec4 worldposition = vec4(0.0);
		
		vec3 watercol = rawWaterColor.rgb / UNDERWATER_I;
		watercol = pow(watercol, vec3(2.3)) * 55;

		#if LIGHT_SHAFT_MODE == 1 || defined END
			float minDistFactor = 5.0;
			float distanceFactor = 0.0;
		#else
			float minDistFactor = 11.0 * LIGHTSHAFT_MIN_DISTANCE;

			float distanceFactor = far / 192.0;
			if (LIGHTSHAFT_DISTANCE_EXPONENT == 1.0) {
				if (distanceFactor > 1.0) minDistFactor *= distanceFactor;
				//else distanceFactor = 0.0;
			} else {
				if (distanceFactor > 1.0) minDistFactor *= pow(distanceFactor, LIGHTSHAFT_DISTANCE_EXPONENT);
				//else distanceFactor = 0.0;
			}

			float fovFactor = gbufferProjection[1][1] / 1.37;
			float x = abs(texCoord.x - 0.5);
			x = 1.0 - x*x;
			x = pow(x, max(3.0 - fovFactor, 0.0));
			minDistFactor *= x;
			maxDist *= x;
		#endif

		#if LIGHT_SHAFT_MODE == 1 || defined END
			int sampleCount = 9;
		#else
			int sampleCount = LIGHTSHAFT_SAMPLE_COUNT;
		#endif

		for(int i = 0; i < sampleCount; i++) {
			#if LIGHT_SHAFT_MODE == 1 || defined END
				float minDist = exp2(i + dither) - 0.9;
			#else
				#if LIGHT_SHAFT_MODE == 2
					float minDist = (i + dither) * minDistFactor;
				#else
					float minDist = pow(i + dither + 0.5, 1.5) * minDistFactor * (0.3 - 0.1 * timeBrightnessM);
				#endif
				if (isEyeInWater == 1) minDist = pow2(i + dither + 0.5) * minDistFactor * 0.045;
			#endif

			float breakFactor = 0.0;

			//if (depth0 >= far*0.9999) break;
			if (minDist >= maxDist) breakFactor = 1.0;

			#if LIGHTSHAFT_BREAK > 0
				if (breakFactor > 0.5) break;
			#endif

			if (depth1 < minDist || (depth0 < minDist && color == vec3(0.0))) break;

			worldposition = getShadowSpace(distx(minDist), texCoord.st);
			//worldposition.z += 0.00002;

			if (length(worldposition.xy * 2.0 - 1.0) < 1.0)	{
				vec3 sample = vec3(shadow2D(shadowtex0, worldposition.xyz).z);
			
				if (depth0 < minDist) sample *= color;

				#if LIGHT_SHAFT_MODE == 1 || defined END
					if (isEyeInWater == 1) sample *= watercol;
					vl += sample;
				#else
					if (isEyeInWater == 1) {
						if (depth0 > minDist) sample *= watercol;
						else sample = watercol;
						float sampleFactor = sqrt(minDist / maxDist) * 1.0;

						#if LIGHT_SHAFT_MODE == 3
							sample *= cosS;
						#endif

						vl += sample * sampleFactor * 0.55;
					}
					if (isEyeInWater == 0) {
						#if LIGHT_SHAFT_MODE == 2
							vl += sample * LIGHTSHAFT_SAMPLE_INTENSITY * 0.25;
						#else
							//float normalCosS = cosS;

							//float dayCosS = pow(normalCosS, 1.25);
							//dayCosS = smoothstep(0.0, 1.0, normalCosS);
							//dayCosS = dayCosS * max(3.0 - length(vl) * 0.13, 0.0);

							sample *= cosS;

							vl += sample * LIGHTSHAFT_SAMPLE_INTENSITY * 0.25;
						#endif
					}
				#endif
			} else {
				vl += 1.0;
			}
			if (breakFactor > 0.5) break;
		}
		vl = sqrt(vl * visibility);

		#if LIGHT_SHAFT_MODE == 1 || defined END
		#else
			#ifdef LIGHTSHAFT_EXPONENT
				#if LIGHT_SHAFT_MODE == 2
					if (isEyeInWater == 0) vl = pow(vl, vec3(1.25 + 0.75 * (sunVisibility * 0.5 + 0.5) * (1.0 - rainStrengthS)));
				#else
					if (isEyeInWater == 0) {
						float vlPower = 2.0 - timeBrightnessM;
						vl = pow(vl, vec3(vlPower));
					}
				#endif
			#endif
		#endif

		vl *= 0.9;
		vl += vl * dither * 0.19;
	}

	#ifdef GBUFFER_CODING
		vl = vec3(0.0);
	#endif
	
	return vl;
}