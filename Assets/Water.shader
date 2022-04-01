Shader "Unlit/Water"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Amplitude ("Amplitude", Float) = 1
        _Wavelength ("Wavelength", Float) = 10
        _Speed ("Speed", Float) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata // vert input
            {
                float4 vertex : POSITION;
                // float2 uv : TEXCOORD0;
            };

            struct v2f // frag input
            {
                // float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            

            fixed4 _Color;
            float _Amplitude;
            float _Wavelength;
            float _Speed;

            v2f vert (appdata v)
            {
                float k = 2 * UNITY_PI / _Wavelength;

                v2f o;

                v.vertex.y = sin((k * v.vertex.x) - (_Time.y * _Speed)) * _Amplitude;

                o.vertex = UnityObjectToClipPos(v.vertex);
                
                // transfer fog
                UNITY_TRANSFER_FOG(o,o.vertex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                return _Color;
            }

            ENDCG
        }
    }
}
