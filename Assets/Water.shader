Shader "Custom/Water"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("NormalMap", 2D) = "bump" {}
        _Smoothness ("Smoothness", Range(0,1)) = 0.5

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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #define UNITY_PI 3.14159265359f

            struct vertInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct fragInput
            {
                float2 uv_MainTex : TEXCOORD0;
                float2 uv_BumpMap: TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_BumpMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _BumpMap_ST;

                half4 _Color;
                float4 _WaveA, _WaveB, _WaveC;
                half _Smoothness;
            CBUFFER_END

            

            // This function samples a point in 3d space to create a wave effect. For example in the vertex or tesselation shader functions.
            float3 GerstnerWave (
                float4 wave, 
                float3 p, 
                inout float3 tangent, 
                inout float3 binormal
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

                // Normal calculations... i will admit this is kind of above my current level of understanding. 
                // But i know that it calculates the current direction of the pixel which will impact how the material interacts with lighting.
                tangent += float3(
                    -d.x * d.x * (steepness * sin(f)),
                    d.x * (steepness * cos(f)),
                    -d.x * d.y * (steepness * sin(f))
                );
                binormal += float3(
                    -d.x * d.y * (steepness * sin(f)),
                    d.y * (steepness * cos(f)),
                    -d.y * d.y * (steepness * sin(f))
                );

                // Sample the position coordinates for every component these positions will move in a circular motion and give the wave-like effect.
                return float3(
                    d.x * (a * cos(f)),
                    a * sin(f),
                    d.y * (a * cos(f))
                );
            }

            // fragInput VOUT;
            // UNITY_INITIALIZE_OUTPUT(VertexOutput, VOUT);

            fragInput vert(vertInput v)
            {
                fragInput o;
                // UNITY_INITIALIZE_OUTPUT(fragInput, o);

                // create variables for use in the wave function
                float3 gridPoint = v.vertex.xyz;
                float3 tangent = float3(1, 0, 0);
                float3 binormal = float3(0, 0, 1);

                // create a value (p) which will accumulate all the results from the 3 different waves
                float3 p = gridPoint;

                // use the gerstner function for each wave and add the results togheter to create a detailed result
                p += GerstnerWave(_WaveA, gridPoint, tangent, binormal);
                p += GerstnerWave(_WaveB, gridPoint, tangent, binormal);
                p += GerstnerWave(_WaveC, gridPoint, tangent, binormal);

                // calculate the normal with the calculated binormal and tangent from the wave function
                float3 normal = normalize(cross(binormal, tangent));

                // set the vertex postition and normal value
                v.vertex.xyz = p;
                v.normal = normal;
                
                // return the final result
                return o;
            }

            half4 frag (fragInput IN) : SV_Target
            {
                // Sample both textures
                // fixed4 c = tex2D(_MainTex, IN.uv_MainTex - _Time.y * 0.25f);
                // // fixed4 d = tex2D(_BlendTex, IN.uv_BlendTex - _Time.y * 0.35f);

                // // Blend texture and assign to albedo value
                // o.Albedo = c.rgb * _Color;
                // o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap - _Time.y * 0.25f));

                // // Material is always fully opaque
                // o.Alpha = 1;

                // // Set Smoothness
                // o.Smoothness = _Smoothness;

                return _Color;
            }
            ENDHLSL
        }
    }
}
