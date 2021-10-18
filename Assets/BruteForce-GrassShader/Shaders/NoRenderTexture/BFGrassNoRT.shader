// MADE BY MATTHIEU HOULLIER
// Copyright 2021 BRUTE FORCE, all rights reserved.
// You are authorized to use this work if you have purchased the asset.
// Mail me at bruteforcegamesstudio@gmail.com if you have any questions or improvements you want.
Shader "BruteForce/Grass"
{
	Properties
	{
		[Header(Tint Colors)]
		[Space]
		_Color("ColorTint",Color) = (0.5 ,0.5 ,0.5,1.0)
		_GroundColor("GroundColorTint",Color) = (0.7 ,0.68 ,0.68,1.0)
		_SelfShadowColor("ShadowColor",Color) = (0.41 ,0.41 ,0.36,1.0)
		_ProjectedShadowColor("ProjectedShadowColor",Color) = (0.45 ,0.42 ,0.04,1.0)
		_GrassShading("GrassShading", Range(0.0, 1)) = 0.197
		_GrassSaturation("GrassSaturation", Float) = 2

		[Header(Textures)]
		[Space]
		_MainTex("Color Grass", 2D) = "white" {}
		_NoGrassTex("NoGrassTexture", 2D) = "white" {}
		_GrassTex("Grass Pattern", 2D) = "white" {}
		_Noise("NoiseColor", 2D) = "white" {}
		_Distortion("DistortionWind", 2D) = "white" {}

		[Header(Geometry Values)]
		[Space]
		_NumberOfStacks("NumberOfStacks", Range(0, 17)) = 12
		_OffsetValue("OffsetValueNormal", Float) = 1
		_OffsetVector("OffsetVector", Vector) = (0,0,0)
		_FadeDistanceStart("FadeDistanceStart", Float) = 16
		_FadeDistanceEnd("FadeDistanceEnd", Float) = 26
		_MinimumNumberStacks("MinimumNumberOfStacks", Range(0, 17)) = 2

		[Header(Rim Lighting)]
		[Space]
		_RimColor("Rim Color", Color) = (0.14, 0.18, 0.09, 1)
		_RimPower("Rim Power", Range(0.0, 8.0)) = 3.14
		_RimMin("Rim Min", Range(0,1)) = 0.241
		_RimMax("Rim Max", Range(0,1)) = 0.62

		[Header(Grass Values)]
		[Space]
		_GrassThinness("GrassThinness", Range(0.01, 2)) = 0.4
		_GrassThinnessIntersection("GrassThinnessIntersection", Range(0.01, 2)) = 0.43
		_TilingN1("TilingOfGrass", Float) = 6.06
		_WindMovement("WindMovementSpeed", Float) = 0.55
		_WindForce("WindForce", Float) = 0.35
		_TilingN3("WindNoiseTiling", Float) = 1
		_GrassCut("GrassCut", Range(0, 1)) = 0
		_TilingN2("TilingOfNoiseColor", Float) = 0.05
		_NoisePower("NoisePower", Float) = 2
	}
		SubShader
		{
			pass
			{
			Tags{ "LightMode" = "ForwardBase" "DisableBatching" = "true" }
			LOD 200
			ZWrite true

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#define SHADOWS_SCREEN
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 normal : NORMAL;
			};

			struct v2g
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float4 objPos : TEXCOORD1;
				float3 normal : TEXCOORD2;
				SHADOW_COORDS(4)
				UNITY_FOG_COORDS(5)
			};

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD1;
				half1 color : TEXCOORD2;
				float3 normal : TEXCOORD3;
				SHADOW_COORDS(4)
				UNITY_FOG_COORDS(5)
			};

			struct SHADOW_VERTEX // This is needed for custom shadow casting
			{
				float4 vertex : POSITION;
			};
			int _NumberOfStacks,_MinimumNumberStacks;
			sampler2D _MainTex;
			sampler2D _NoGrassTex;
			float4 _MainTex_ST;
			sampler2D _Distortion;
			sampler2D _GrassTex;
			sampler2D _Noise;
			float _TilingN1;
			float _TilingN2, _WindForce;
			float4 _Color, _SelfShadowColor, _GroundColor, _ProjectedShadowColor;
			float4 _OffsetVector;
			float _TilingN3;
			float _WindMovement, _OffsetValue;
			half _GrassThinness, _GrassShading, _GrassThinnessIntersection, _GrassCut;
			half4 _RimColor;
			half _RimPower, _NoisePower, _GrassSaturation, _FadeDistanceStart, _FadeDistanceEnd;
			half _RimMin, _RimMax;

			v2g vert(appdata v)
			{
				v2g o;
				o.objPos = v.vertex;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o._ShadowCoord = ComputeScreenPos(o.pos);
				o.normal = v.normal;

				TRANSFER_VERTEX_TO_FRAGMENT(o);
				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}

			#define UnityObjectToWorld(o) mul(unity_ObjectToWorld, float4(o.xyz,1.0))
			[maxvertexcount(54)]
			void geom(triangle v2g input[3], inout TriangleStream<g2f> tristream)
			{
				g2f o;
				SHADOW_VERTEX v;

				_OffsetValue *= 0.01;
				// Loop 3 times for the base ground geometry
				for (int i = 0; i < 3; i++)
				{
					o.uv = input[i].uv;
					o.pos = input[i].pos;
					o.color = 0.0 + _GrassCut;
					o.normal = normalize(mul(float4(input[i].normal, 0.0), unity_WorldToObject).xyz);
					o.worldPos = UnityObjectToWorld(input[i].objPos);
					o._ShadowCoord = input[i]._ShadowCoord;
					UNITY_TRANSFER_FOG(o, o.pos);
					tristream.Append(o);
				}
				tristream.RestartStrip();

				float dist = distance(_WorldSpaceCameraPos, UnityObjectToWorld((input[0].objPos / 3 + input[1].objPos / 3 + input[2].objPos / 3)));
				if (dist > 0)
				{
					int NumStacks = lerp(_NumberOfStacks + 1, 0, (dist - _FadeDistanceStart)*(1 / max(_FadeDistanceEnd - _FadeDistanceStart, 0.0001)));//Clamp because people will start dividing by 0
					_NumberOfStacks = min(clamp(NumStacks, clamp(_MinimumNumberStacks, 0, _NumberOfStacks), 17), _NumberOfStacks);
				}

				float4 P; // P is shadow coords new position
				float4 objSpace; // objSpace is the vertex new position
				// Loop 3 times * numbersOfStacks for the grass
					for (float i = 1; i <= _NumberOfStacks; i++)
					{
						float4 offsetNormal = _OffsetVector * i*0.01;
						for (int ii = 0; ii < 3; ii++)
						{
							float thicknessModifier = 1;
							float dist = distance(_WorldSpaceCameraPos, UnityObjectToWorld(input[ii].objPos));
							if (dist > 0)
							{
								thicknessModifier = lerp(0.1*0.01, _OffsetValue, (dist - 1)*(1 / max(3 - 1, 0.0001)));//Clamp because people will start dividing by 0
								thicknessModifier = clamp(thicknessModifier, 0.1*0.01, _OffsetValue);
							}
							P = input[ii]._ShadowCoord + _OffsetVector * _NumberOfStacks*0.01;
							float4 NewNormal = float4(normalize(input[ii].normal),0);
							objSpace = float4(input[ii].objPos + NewNormal * thicknessModifier*i + offsetNormal);
							o.color = (i / (_NumberOfStacks - _GrassCut));
							o.uv = input[ii].uv;
							o.pos = UnityObjectToClipPos(objSpace);
							o._ShadowCoord = P;
							o.worldPos = UnityObjectToWorld(objSpace);
							o.normal = normalize(mul(float4(input[ii].normal, 0.0), unity_WorldToObject).xyz);

							v.vertex = mul(unity_WorldToObject, UnityObjectToWorld(objSpace));
							TRANSFER_VERTEX_TO_FRAGMENT(o);
							UNITY_TRANSFER_FOG(o, o.pos);
							tristream.Append(o);
						}
						tristream.RestartStrip();
				}
			}
			half4 frag(g2f i) : SV_Target
			{
				float2 dis = tex2D(_Distortion, i.uv  *_TilingN3 + _Time.xx * 3 * _WindMovement);
				float displacementStrengh = 0.6* (((sin(_Time.y + dis * 5) + sin(_Time.y*0.5 + 1.051)) / 5.0) + 0.15*dis); //hmm math
				dis = dis * displacementStrengh*(i.color.r*1.3)*_WindForce;

				float3 normalDir = i.normal;
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				float rim = 1 - saturate(dot(viewDir, normalDir));
				float3 rimLight = pow(rim, _RimPower);
				rimLight = smoothstep(_RimMin, _RimMax, rimLight);

				half4 col = tex2D(_MainTex, i.uv + dis.xy*0.09);
				half4 colGround = tex2D(_MainTex, i.uv + dis.xy*0.05);

				float3 noise = tex2D(_Noise, i.uv*_TilingN2 + dis.xy)*_NoisePower;
				float3 grassPattern = tex2D(_GrassTex, i.uv*_TilingN1 + dis.xy);
				half3 NoGrass = tex2D(_NoGrassTex, i.uv + dis.xy*0.05);

				half alpha = step(1 - ((col.x + col.y + col.z + grassPattern.x) * _GrassThinness)*((2 - i.color.r)*NoGrass.r*grassPattern.x), (1 - i.color.r)*(NoGrass.r*grassPattern.x)*_GrassThinness - dis.x * 5);
				alpha = lerp(alpha, alpha + (grassPattern.x*NoGrass.r*(1 - i.color.r))*_GrassThinnessIntersection ,1 - NoGrass.r);

				if (i.color.r >= 0.01)
				{
					if (alpha - (i.color.r) < -0.02)discard;
				}
				_Color *= 2;
				col.xyz = (pow(col, _GrassSaturation) * _GrassSaturation)*float3(_Color.x, _Color.y, _Color.z);
				col.xyz *= saturate(lerp(_SelfShadowColor, 1, pow(i.color.x, 1.1)) + (_GrassShading - noise.x*dis.x * 2) + (1 - NoGrass.r) - noise.x*dis.x * 2);
				col.xyz *= _Color;

				if (i.color.r <= 0.01)
				{
					colGround.xyz = ((1 - NoGrass.r)*_GroundColor*_GroundColor * 2);
					col.xyz = lerp(col.xyz, col.xyz * colGround.xyz, 1 - NoGrass.r);
				}

				float shadowmap = LIGHT_ATTENUATION(i);
				half3 shadowmapColor = lerp(_ProjectedShadowColor,1,shadowmap);

				col.xyz += _RimColor.rgb * pow(rimLight, _RimPower);
				col.xyz = col.xyz * saturate(shadowmapColor);
				col.xyz *= _LightColor0;
				UNITY_APPLY_FOG(i.fogCoord, col);

				return col;
			}
			ENDCG
		}

		// SHADOW CASTING PASS, this will redraw geometry so keep this pass disabled if you want to save performance
		// Keep it if you want depth for post process or if you're using deferred rendering
		Pass{
				Tags {"LightMode" = "ShadowCaster" "DisableBatching" = "true"  }
				//Tags{ "LightMode" = "ForwardBase" "DisableBatching" = "true" }
				//Tag for debugging only

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom

			#include "UnityCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
			float4 normal : NORMAL;
		};

		struct v2g
		{
			float2 uv : TEXCOORD0;
			float4 pos : SV_POSITION;
			float4 objPos : TEXCOORD1;
			float3 normal : TEXCOORD3;
		};

		struct g2f
		{
			float2 uv : TEXCOORD0;
			float3 worldPos : TEXCOORD1;
			float3 normal : TEXCOORD3;
			float1 color : TEXCOORD2;
			V2F_SHADOW_CASTER;
		};

		struct SHADOW_VERTEX
		{
			float4 vertex : POSITION;
		};

			sampler2D _MainTex;
			sampler2D _NoGrassTex;
			sampler2D _Noise;

			int _NumberOfStacks, _MinimumNumberStacks;
			float4 _MainTex_ST;
			sampler2D _Distortion;
			sampler2D _GrassTex;
			float _TilingN1;
			float _WindForce, _TilingN2;
			float4 _OffsetVector;
			float _TilingN3;
			float _WindMovement, _OffsetValue, _FadeDistanceStart, _FadeDistanceEnd;
			half _GrassThinness, _GrassThinnessIntersection, _GrassCut, _NoisePower;

					v2g vert(appdata v)
					{
						v2g o;
						o.objPos = v.vertex;
						o.pos = UnityObjectToClipPos(v.vertex);
						o.uv = TRANSFORM_TEX(v.uv, _MainTex);
						o.normal = v.normal;
						return o;
					}

					#define UnityObjectToWorld(o) mul(unity_ObjectToWorld, float4(o.xyz,1.0))
					[maxvertexcount(54)]
					void geom(triangle v2g input[3], inout TriangleStream<g2f> tristream) {

						g2f o;
						SHADOW_VERTEX v;

						_OffsetValue *= 0.01;

						for (int i = 0; i < 3; i++)
						{
							o.uv = input[i].uv;
							o.pos = input[i].pos;
							o.color = float3(0 + _GrassCut, 0 + _GrassCut, 0 + _GrassCut);
							o.normal = normalize(mul(float4(input[i].normal, 0.0), unity_WorldToObject).xyz);
							o.worldPos = UnityObjectToWorld(input[i].objPos);

							tristream.Append(o);
						}
						float4 P;
						float4 objSpace;
						tristream.RestartStrip();

						float dist = distance(_WorldSpaceCameraPos, UnityObjectToWorld((input[0].objPos / 3 + input[1].objPos / 3 + input[2].objPos / 3)));
						if (dist > 0)
						{
							int NumStacks = lerp(_NumberOfStacks + 1, 0, (dist - _FadeDistanceStart)*(1 / max(_FadeDistanceEnd - _FadeDistanceStart, 0.0001)));//Clamp because people will start dividing by 0
							_NumberOfStacks = min(clamp(NumStacks, clamp(_MinimumNumberStacks, 0, _NumberOfStacks), 17), _NumberOfStacks);
						}

						for (float i = 1; i <= _NumberOfStacks; i++)
						{
							float4 offsetNormal = _OffsetVector * i*0.01;
							for (int ii = 0; ii < 3; ii++)
							{
								float thicknessModifier = 1;
								float dist = distance(_WorldSpaceCameraPos, UnityObjectToWorld(input[ii].objPos));
								if (dist > 0)
								{
									thicknessModifier = lerp(0.1*0.01, _OffsetValue, (dist - 1)*(1 / max(3 - 1, 0.0001)));//Clamp because people will start dividing by 0
									thicknessModifier = clamp(thicknessModifier, 0.1*0.01, _OffsetValue);
								}
								float4 NewNormal = float4(normalize(input[ii].normal), 0);
								objSpace = float4(input[ii].objPos + NewNormal * thicknessModifier*i + offsetNormal);
								o.color = (i / (_NumberOfStacks - _GrassCut));
								o.uv = input[ii].uv;
								o.pos = UnityObjectToClipPos(objSpace);

								o.worldPos = UnityObjectToWorld(objSpace);
								o.normal = normalize(mul(float4(input[ii].normal, 0.0), unity_WorldToObject).xyz);
								tristream.Append(o);
							}
							tristream.RestartStrip();
						}
					}

			float4 frag(g2f i) : SV_Target
			{

				float2 dis = tex2D(_Distortion, i.uv  *_TilingN3 + _Time.xx * 3 * _WindMovement);
				float displacementStrengh = 0.6* (((sin(_Time.y + dis * 5) + sin(_Time.y*0.5 + 1.051)) / 5.0) + 0.15*dis); //hmm math
				dis = dis * displacementStrengh*(i.color.r*1.3)*_WindForce;

				half4 col = tex2D(_MainTex, i.uv + dis.xy*0.09);
				float3 noise = tex2D(_Noise, i.uv*_TilingN2 + dis.xy)*_NoisePower;
				float3 grassPattern = tex2D(_GrassTex, i.uv*_TilingN1 + dis.xy);
				half3 NoGrass = tex2D(_NoGrassTex, i.uv + dis.xy*0.05);

				half alpha = step(1 - ((col.x + col.y + col.z + grassPattern.x) * _GrassThinness)*((2 - i.color.r)*NoGrass.r*grassPattern.x), ((1 - i.color.r))*(NoGrass.r*grassPattern.x)*_GrassThinness - dis.x * 5);
				alpha = lerp(alpha, alpha + (grassPattern.x*NoGrass.r*(1 - i.color.r))*_GrassThinnessIntersection ,1 - NoGrass.r);

				if (i.color.r >= 0.01)
				{
					if (alpha - (i.color.r) < -0.02)discard;
				}
				SHADOW_CASTER_FRAGMENT(i)
					//return col; //For debugging
			}
			ENDCG
		}

		} Fallback "VertexLit"
}
