Shader "Custom/Water"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("NormalMap", 2D) = "bump" {}
        _TesselationFactor ("TesselationFactor", Range(1, 50)) = 1

        _WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1,1,0.25,60)
        _WaveB ("Wave B", Vector) = (1,0.6,0.25,31)
        _WaveC ("Wave C", Vector) = (1,1,0.25,18)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }
        
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma hull hullProgram
            #pragma domain domainProgram

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "MyTessellation.cginc"

            #define UNITY_PI 3.14159265359f

            // Struct for input to the shader stage
            struct vertInput
            {
                float4 vertex   : POSITION;
                float2 uv       : TEXCOORD0;
            };

            // Struct for determining how mesh will be tesselated, used in the patchConstant function
            struct tessellationFactors
            {
                float edge[3]   : SV_TessFactor;
                float inside    : SV_InsideTessFactor;
            };

            // Struct for input to the hull stage
            struct hullInput
            {
                float4 vertex   : POSITION;
                float2 uv       : TEXCOORD0;
            };

            // Struct for input to the domain stage
            struct domainInput
            {
                float4 vertex   : POSITION;
                float2 uv       : TEXCOORD0;
            };

            // Struct for input to the fragment stage
            struct fragInput
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_BumpMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _BumpMap_ST;

                float4 _Color;
                float4 _WaveA, _WaveB, _WaveC;
                half _Smoothness;
                float _TesselationFactor;
            CBUFFER_END

            // This function samples a point in 3d space to create a wave effect. For example in the vertex or tesselation shader functions.
            float3 GerstnerWave (
                float4 wave, 
                float3 p
            ) {
                // Create variables for wave config these will influence how the final waves will look. 
                // steepness is stored in the z component of the wave vector and the wavelength is stored in the w component.
                float steepness = wave.z;

                // k is the original point to sample the wave from
                float k = 2 * UNITY_PI / wave.w;
                // The value c is used to control the speed of the wave
                float c = sqrt(9.8 / k);

                // normalize the direction of the wave.
                float2 d = normalize(wave.xy);

                // create a variable to use when sampeling the position. This formula makes sure the wave will flow in the configured direction (d)
                // also subtract by the speed of the wave (c) and multiply by the current time to make the wave appear like it is moving.
                float f = k * (dot(d, p.xz) - c * _Time.y);

                // the variable a is used as a kind of amplitude value. 
                // dividing the steepness bij the original sample value (k) prevents that the sample point will overshoot the sine wave and make sure there are no weird looping effects
                float a = steepness / k;

                // Sample the position coordinates for every component these positions will move in a circular motion and give the wave-like effect.
                return float3(
                    d.x * (a * cos(f)),
                    a * sin(f),
                    d.y * (a * cos(f))
                );
            }

            hullInput vert(vertInput v)
            {
                // Hi Vincent, i know this vertex shader looks really empty, but i have a reason for this.
                // The effect i am trying to create is a gersner wave with a LOD slider (dynamic tesselation factor)
                // The transformation of the vertex positions is better done in the domain stage for my effect.
                // If i only do this in the vertex stage the tesselated vertices will not behave properly so i hope you see this as a good reason.
                // I also use the tesselation factor property in the patchConstant function to determine how the vertices should be tesselated,
                // so there is also some tesselation specific functionality implemented there and not only vertex transformation.

                // declare output for hull stage...
                hullInput o;

                // passthrough vertex position
                o.vertex = v.vertex;

                // assign uv coordinate (both textures are of the same size so its fine)
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                // return the final result to the hull stage
                return o;
            }

            tessellationFactors patchConstantFunc(InputPatch<hullInput, 3> patch) {
                tessellationFactors f;

                // Assign the _TesselationFactor property value to the edge and inside constant values 
                f.edge[0] = _TesselationFactor;
				f.edge[1] = _TesselationFactor;
				f.edge[2] = _TesselationFactor;
				f.inside = _TesselationFactor;

				return f;
            }

            [domain("tri")]
			[outputcontrolpoints(3)]
			[outputtopology("triangle_cw")]
			[partitioning("integer")]
			[patchconstantfunc("patchConstantFunc")]
            domainInput hullProgram(InputPatch<hullInput, 3> patch, uint id : SV_OutputControlPointID)
            {
                //return vertex by using the passed patch and id
                return patch[id];
            }

            [domain("tri")]
            fragInput domainProgram(tessellationFactors factors, OutputPatch<domainInput, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
            {
				fragInput i;

                // Interpolate the new vertex position using the barycentric coordinates
                float4 vertexPosition = barycentricCoordinates.x * patch[0].vertex + barycentricCoordinates.y * patch[1].vertex + barycentricCoordinates.z * patch[2].vertex;

                // create variables for use in the wave function
                float3 gridPoint = vertexPosition.xyz;

                // create a value (p) which will accumulate all the results from the 3 different waves
                float3 p = gridPoint;

                // use the gerstner function for each wave and add the results togheter to create a detailed result
                p += GerstnerWave(_WaveA, gridPoint);
                p += GerstnerWave(_WaveB, gridPoint);
                p += GerstnerWave(_WaveC, gridPoint);

                // Convert object space vertex position to HClip
                i.positionHCS = TransformObjectToHClip(p);

                // Interpolate the new uv coordinates using the barycentric coordinates
                float2 uv = (barycentricCoordinates.x * patch[0].uv + barycentricCoordinates.y * patch[1].uv + barycentricCoordinates.z * patch[2].uv).xy;

                // assign interpolatd uv coordinate
                i.uv = TRANSFORM_TEX(uv, _MainTex);
        
                // send the interpolated data to the fragment stage
				return i;
			}

            float4 frag(fragInput IN) : SV_Target
            {
                float3 LightDirection = float3(0.6, 1, 0);
                float scrollSpeed = 0.1f;

                // Sample the texture using the scrollspeed
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv - _Time.y * scrollSpeed);

                // Convert normal space from 0~1 to -1~1
                float4 normal = 2.0 * SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, IN.uv - _Time.y * scrollSpeed) - 1.0;
                // Calculate the amount of light reflected using the dot product
                float lightAmount = max(dot(normal.xyz, LightDirection), 0.0);

                // Create variable to use for combining the texel color with the lighted color
                float4 color = _Color;
                color.rgb *= lightAmount;

                // return the combined texel color and lighted color
                return tex * color;
            }
            
            ENDHLSL
        }
    }
}
