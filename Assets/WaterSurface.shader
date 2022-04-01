Shader "Custom/WaterSurface"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Amplitude ("Amplitude", Float) = 1
        _Wavelength ("Wavelength", Float) = 10
        _Speed ("Speed", Float) = 1

        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        // _MainTex ("Albedo (RGB)", 2D) = "white" {}
        // _Metallic ("Metallic", Range(0,1)) = 0.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM

        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        struct appdata // vert input
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 texcoord1 : TEXCOORD1;
            float4 texcoord2 : TEXCOORD2;
        };

        struct Input // surf in struct
        {
            float4 vertex : SV_POSITION;
        };

        fixed4 _Color;
        float _Amplitude;
        float _Wavelength;
        float _Speed;

        half _Glossiness;
        // half _Metallic;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        Input vert (inout appdata v)
        {
            Input o;

            float k = 2 * UNITY_PI / _Wavelength;
            float f = k * (v.vertex.x - _Speed * _Time.y);

            v.vertex.y = sin(f) * _Amplitude;
            v.vertex.x += cos(f) * _Amplitude;

            o.vertex = UnityObjectToClipPos(v.vertex);

            float3 tangent = normalize(float3(
                1 - k * _Amplitude * sin(f), 
                k * _Amplitude * cos(f), 
                0
            ));

            float3 normal = float3(-tangent.y, tangent.x, 0);

            v.normal = normal;
            
            // transfer fog
            // UNITY_TRANSFER_FOG(o, o.vertex);
            
            return o;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            // fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            // o.Albedo = c.rgb;
            o.Albedo = _Color;

            // Metallic and smoothness come from slider variables
            // o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            // o.Alpha = c.a;
            o.Alpha = 1;
        }

        ENDCG
    }

    FallBack "Diffuse"
}
