Shader "koturn/WireWorld/UnlitEmissionHS"
{
    Properties
    {
        [HideInInspector]
        _RenderingMode("Rendering Mode", Int) = 2

        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcFactor("Blend Source Factor", Int) = 5  // Default: SrcAlpha

        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstFactor("Blend Destination Factor", Int) = 10  // Default: OneMinusSrcAlpha

        [Enum(Off, 0, On, 1)]
        _ZWrite("ZWrite", Int) = 0  // Default: Off


        [Enum(UnityEngine.Rendering.CompareFunction)]
        _ZTest("ZTest", Int) = 4  // Default: LEqual

        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull("Culling Mode", Int) = 2  // Default: Back


        [Toggle]
        _AlphaTest("Alpha test", Int) = 0

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5


        [NoScaleOffset]
        _MainTex ("Main texture", 2D) = "white" {}
        _Color ("Multiplicative color for _MainTex", Color) = (1.0, 1.0, 1.0, 1.0)

        [NoScaleOffset]
        _EmissionTex ("Emission texture", 2D) = "black" {}

        [HDR]
        _EmissionColor ("Multiplicative color for _EmissionTex", Color) = (0.0, 0.0, 0.0, 1.0)

        [Toggle]
        _HueOnly ("Treats Hue only, ignore offset of Saturation and Value", Float) = 0
        _TimeScale ("Time multiplier for Hue Shift", Float) = 0.1
        _HueOffset ("Offset of Hue (H)", Range(0.0, 1.0)) = 0.0
        _SaturationOffset ("Offset of Saturation (S)", Range(-1.0, 1.0)) = 0.0
        _ValueOffset ("Offset of Value (V)", Range(-1.0, 1.0)) = 0.0
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "Queue" = "Transparent"
        }

        Cull [_Cull]
        Blend [_SrcFactor] [_DstFactor]
        ZWrite Off
        ZTest LEqual

        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local_fragment _ _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _HUEONLY_ON

            #include "UnityCG.cginc"


            /*!
             * @brief Input data structure for vertex shader function: vert().
             */
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            /*!
             * @brief Output data structure of vertex shader function, vert()
             * and input data of fragment shader, frag().
             */
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            UNITY_DECLARE_TEX2D(_MainTex);
            uniform float4 _Color;
            uniform float _Cutoff;
            UNITY_DECLARE_TEX2D(_EmissionTex);
            uniform float4 _EmissionColor;
            uniform float _TimeScale;
            uniform float _HueOffset;
#ifndef _HUEONLY_ON
            uniform float _SaturationOffset;
            uniform float _ValueOffset;
#endif  // !_HUEONLY_ON


            inline float3 rgb2hsv(float3 rgb);
            inline float3 hsv2rgb(float3 hsv);
            inline float3 rgbAddHue(float3 rgb, float hue);
            inline float3 rgbAddHsv(float3 rgb, float3 hsvDiff);


            /*!
             * @brief Vertex shader function
             * @param [in] v  Input data.
             * @return Data for fragment shader.
             */
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            /*!
             * @brief Fragment shader function
             * @param [in] i  Input of custom render texture.
             * @return RGBA value of texel.
             */
            fixed4 frag(v2f i) : SV_Target
            {
                float4 col = UNITY_SAMPLE_TEX2D(_MainTex, i.uv) * _Color;
#if _ALPHATEST_ON
                clip(col.a - _Cutoff);
#endif  // _ALPHATEST_ON

                const float4 e = UNITY_SAMPLE_TEX2D(_EmissionTex, i.uv) * _EmissionColor;
                col.rgb += e.rgb;

                const float hueDiff = _Time.y * _TimeScale + _HueOffset;
#ifdef _HUEONLY_ON
                col.rgb = rgbAddHue(col.rgb, hueDiff);
#else
                col.rgb = hsv2rgb(rgb2hsv(col.rgb) + float3(hueDiff, _SaturationOffset, _ValueOffset));
#endif  // _HUEONLY_ON
                return col;
            }


            /*!
             * @brief Convert from RGB to HSV.
             *
             * @param [in] rgb  Three-dimensional vector of RGB.
             * @return Three-dimensional vector of HSV.
             */
            inline float3 rgb2hsv(float3 rgb)
            {
                static const float4 k = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                static const float e = 1.0e-10;

                const float4 p = rgb.g < rgb.b ? float4(rgb.bg, k.wz) : float4(rgb.gb, k.xy);
                const float4 q = rgb.r < p.x ? float4(p.xyw, rgb.r) : float4(rgb.r, p.yzx);
                const float d = q.x - min(q.w, q.y);
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            /*!
             * @brief Convert from HSV to RGB.
             *
             * @param [in] hsv  Three-dimensional vector of HSV.
             * @return Three-dimensional vector of RGB.
             */
            inline float3 hsv2rgb(float3 hsv)
            {
                static const float4 k = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);

                const float3 p = abs(frac(hsv.xxx + k.xyz) * 6.0 - k.www);
                return hsv.z * lerp(k.xxx, saturate(p - k.xxx), hsv.y);
            }

            /*!
             * @brief Add hue to RGB color.
             *
             * @param [in] rgb  Three-dimensional vector of RGB.
             * @param [in] hue  Scalar of hue.
             * @return Three-dimensional vector of RGB.
             */
            inline float3 rgbAddHue(float3 rgb, float hue)
            {
                float3 hsv = rgb2hsv(rgb);
                hsv.x += hue;
                return hsv2rgb(hsv);
            }

            /*!
             * @brief Add HSV to RGB color.
             *
             * @param [in] rgb  Three-dimensional vector of RGB.
             * @param [in] hsv  Three-dimensional vector of different value of HSV.
             * @return Three-dimensional vector of RGB.
             */
            inline float3 rgbAddHsv(float3 rgb, float3 hsvDiff)
            {
                float3 hsv = rgb2hsv(rgb) + hsvDiff;
                hsv.yz = saturate(hsv.yz);
                return hsv2rgb(hsv);
            }
            ENDCG
        }
    }

    Fallback "Diffuse"
    CustomEditor "Koturn.WireWorld.UnlitEmissionHSGUI"
}
