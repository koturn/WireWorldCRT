Shader "koturn/WireWorld/CRT/WireWorld"
{
    /*
     * Wireworld
     *
     * https://en.wikipedia.org/wiki/Wireworld
     *
     * Rules:
     *
     * A Wireworld cell can be in one of four different states, usually
     * numbered 0-3 in software, modeled by colors in the examples here:
     *
     * 0. empty (black)
     * 1. electron head (blue)
     * 2. electron tail (red)
     * 3. conductor (yellow)
     *
     * As in all cellular automata, time proceeds in discrete steps called
     * generations (sometimes "gens" or "ticks"). Cells behave as follows:
     *
     * - empty -> empty,
     * - electron head -> electron tail,
     * - electron tail -> conductor,
     * - conductor -> electron head if exactly one or two of the neighbouring
     *   cells are electron heads, otherwise remains conductor.
     */
    Properties
    {
        _Color ("Color of Empty", Color) = (0.0, 0.0, 0.0, 0.0)
        _HeadColor ("Color of Head", Color) = (0.0, 0.0, 1.0, 1.0)
        _TailColor ("Color of Tail", Color) = (1.0, 0.0, 0.0, 1.0)
        _ConductorColor ("Color of Conductor", Color) = (1.0, 1.0, 0.0, 1.0)
    }
    SubShader
    {
        ZTest Always
        ZWrite Off

        Pass
        {
            Name "Update"

            CGPROGRAM
            #pragma target 3.0

            #include "UnityCustomRenderTexture.cginc"

            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag

            inline float sqdist(float3 x, float3 y);

            //! Allowable floating point calculation error.
            static const float eps = 1.0 / (255.0 * 255.0);
            //! Four-dimensional vector with all elements 1.
            static const float4 ones4 = float4(1.0, 1.0, 1.0, 1.0);
            //! Color of Empty.
            uniform float4 _Color;
            //! Color of Head.
            uniform float4 _HeadColor;
            //! Color of Tail.
            uniform float4 _TailColor;
            //! Color of Conductor.
            uniform float4 _ConductorColor;

            /*!
             * @brief Fragment shader function.
             * @param [in] i  Input of custom render texture.
             * @return RGBA value of texel.
             */
            float4 frag(v2f_customrendertexture i) : COLOR
            {
                const float2 d = 1.0 / _CustomRenderTextureInfo.xy;
                const float2 uv = i.globalTexcoord;

                const float cnt = dot(
                    step(
                        float4(
                            sqdist(_HeadColor.rgb, tex2D(_SelfTexture2D, uv - d).rgb),
                            sqdist(_HeadColor.rgb, tex2D(_SelfTexture2D, float2(uv.x, uv.y - d.y)).rgb),
                            sqdist(_HeadColor.rgb, tex2D(_SelfTexture2D, float2(uv.x + d.x, uv.y - d.y)).rgb),
                            sqdist(_HeadColor.rgb, tex2D(_SelfTexture2D, float2(uv.x - d.x, uv.y)).rgb)),
                        eps)
                    + step(
                        float4(
                            sqdist(_HeadColor.rgb, tex2D(_SelfTexture2D, float2(uv.x + d.x, uv.y)).rgb),
                            sqdist(_HeadColor.rgb, tex2D(_SelfTexture2D, float2(uv.x - d.x, uv.y + d.y)).rgb),
                            sqdist(_HeadColor.rgb, tex2D(_SelfTexture2D, float2(uv.x, uv.y + d.y)).rgb),
                            sqdist(_HeadColor.rgb, tex2D(_SelfTexture2D, uv + d).rgb)),
                        eps),
                    ones4);

                const float4 color = tex2D(_SelfTexture2D, uv);
                const float3 selector3 = step(
                    float3(
                        sqdist(_HeadColor.rgb, color.rgb),
                        sqdist(_TailColor.rgb, color.rgb),
                        sqdist(_ConductorColor.rgb, color.rgb)),
                    eps);
                const float4 selector = float4(selector3, !(selector3.x || selector3.y || selector3.z));

                return _TailColor * selector.x
                    + _ConductorColor * selector.y
                    + ((cnt == 1.0 || cnt == 2.0) ? _HeadColor : _ConductorColor) * selector.z
                    + _Color * selector.w;
            }

            /*
             * @brief Calculate square distance.
             * @param [in] x  First three-dimensional vector.
             * @param [in] y  Second three-dimensional vector.
             * @return Squared distance between x and y.
             */
            inline float sqdist(float3 x, float3 y)
            {
                const float3 v = x - y;
                return dot(v, v);
            }
            ENDCG
        }
    }
}
