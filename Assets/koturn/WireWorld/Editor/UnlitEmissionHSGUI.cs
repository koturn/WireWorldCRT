using System;
using UnityEditor;
using UnityEngine;


namespace Koturn.WireWorld
{
    /// <summary>
    /// <see cref="ShaderGUI"/> for UnlitEmissionHS.shader.
    /// </summary>
    public class UnlitEmissionHSGUI : ShaderGUI
    {
        /// <summary>
        /// Blend Mode
        /// </summary>
        public enum RenderingMode
        {
            Opaque,
            Cutout,
            Transparent,
            Additive,
            Multiply,
            Custom
        }

        /// <summary>
        /// Draw common items.
        /// </summary>
        /// <param name="me">The <see cref="MaterialEditor"/> that are calling this <see cref="OnGUI(MaterialEditor, MaterialProperty[])"/> (the 'owner')</param>
        /// <param name="mps">Material properties of the current selected shader</param>
        public override void OnGUI(MaterialEditor me, MaterialProperty[] mps)
        {
            EditorGUILayout.LabelField("Rendering Options", EditorStyles.boldLabel);
            using (new EditorGUILayout.VerticalScope(GUI.skin.box))
            {
                DrawBlendMode(me, mps);
                ShaderProperty(me, mps, "_ZTest");
                ShaderProperty(me, mps, "_Cull");
            }

            EditorGUILayout.Space();

            EditorGUILayout.LabelField("Main Texture & Color", EditorStyles.boldLabel);
            using (new EditorGUILayout.VerticalScope(GUI.skin.box))
            {
                TexturePropertySingleLine(me, mps, "_MainTex", "_Color");
            }

            EditorGUILayout.Space();

            EditorGUILayout.LabelField("Emission Texture & Color", EditorStyles.boldLabel);
            using (new EditorGUILayout.VerticalScope(GUI.skin.box))
            {
                TextureWithHdrColor(me, "Emission setting", "Emission setting", mps, "_EmissionTex", "_EmissionColor");
            }

            EditorGUILayout.Space();

            EditorGUILayout.LabelField("Hue Shift", EditorStyles.boldLabel);
            using (new EditorGUILayout.VerticalScope(GUI.skin.box))
            {
                var mpHueOnly = FindProperty("_HueOnly", mps);
                ShaderProperty(me, mpHueOnly);
                ShaderProperty(me, mps, "_TimeScale");
                ShaderProperty(me, mps, "_HueOffset");
                if (mpHueOnly.floatValue < 0.5)
                {
                    ShaderProperty(me, mps, "_SaturationOffset");
                    ShaderProperty(me, mps, "_ValueOffset");
                }
            }

            EditorGUILayout.Space();

            GUILayout.Label("Advanced Options", EditorStyles.boldLabel);
            using (new EditorGUILayout.VerticalScope(GUI.skin.box))
            {
                me.RenderQueueField();
#if UNITY_5_6_OR_NEWER
                // me.EnableInstancingField();
                me.DoubleSidedGIField();
#endif  // UNITY_5_6_OR_NEWER
            }
        }

        /// <summary>
        /// Draw inspector items of <see cref="RenderingMode"/>.
        /// </summary>
        /// <param name="me">A <see cref="MaterialEditor"/></param>
        /// <param name="mps"><see cref="MaterialProperty"/> array</param>
        private static void DrawBlendMode(MaterialEditor me, MaterialProperty[] mps)
        {
            using (var ccScope = new EditorGUI.ChangeCheckScope())
            {
                var blendMode = FindProperty("_RenderingMode", mps);
                var mode = (RenderingMode)EditorGUILayout.EnumPopup(blendMode.displayName, (RenderingMode)blendMode.floatValue);
                blendMode.floatValue = (float)mode;
                if (mode == RenderingMode.Custom)
                {
                    ShaderProperty(me, mps, "_ZWrite");
                    ShaderProperty(me, mps, "_SrcFactor");
                    ShaderProperty(me, mps, "_DstFactor");

                    using (new EditorGUI.IndentLevelScope())
                    {
                        var mpAlphaTest = FindProperty("_AlphaTest", mps);
                        ShaderProperty(me, mpAlphaTest);
                        if (mpAlphaTest.floatValue >= 0.5)
                        {
                            ShaderProperty(me, mps, "_Cutoff");
                        }
                    }
                }
                else
                {
                    if (ccScope.changed)
                    {
                        foreach (var obj in blendMode.targets)
                        {
                            ApplyBlendMode(obj as Material, mode);
                        }
                    }
                    if (mode == RenderingMode.Cutout)
                    {
                        using (new EditorGUI.IndentLevelScope())
                        {
                            ShaderProperty(me, mps, "_Cutoff");
                        }
                    }
                }
            }
        }


        /// <summary>
        /// Change blend of <paramref name="material"/>.
        /// </summary>
        /// <param name="material">Target material</param>
        /// <param name="blendMode">Blend mode</param>
        private static void ApplyBlendMode(Material material, RenderingMode blendMode)
        {
            switch (blendMode)
            {
                case RenderingMode.Opaque:
                    material.SetOverrideTag("RenderType", "");
                    material.SetInt("_SrcFactor", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstFactor", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.SetInt("_AlphaTest", 0);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.renderQueue = -1;
                    break;
                case RenderingMode.Cutout:
                    material.SetOverrideTag("RenderType", "TransparentCutout");
                    material.SetInt("_SrcFactor", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstFactor", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.SetInt("_AlphaTest", 1);
                    material.EnableKeyword("_ALPHATEST_ON");
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                    break;
                case RenderingMode.Transparent:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcFactor", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstFactor", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetInt("_ZWrite", 0);
                    material.SetInt("_AlphaTest", 0);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                case RenderingMode.Additive:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcFactor", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstFactor", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_ZWrite", 0);
                    material.SetInt("_AlphaTest", 0);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                case RenderingMode.Multiply:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcFactor", (int)UnityEngine.Rendering.BlendMode.DstColor);
                    material.SetInt("_DstFactor", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 0);
                    material.SetInt("_AlphaTest", 0);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                default:
                    throw new ArgumentOutOfRangeException(nameof(blendMode), blendMode, null);
            }
        }

        /// <summary>
        /// Draw default item of specified shader property.
        /// </summary>
        /// <param name="me">A <see cref="MaterialEditor"/></param>
        /// <param name="mps"><see cref="MaterialProperty"/> array</param>
        /// <param name="propName">Name of shader property</param>
        private static void ShaderProperty(MaterialEditor me, MaterialProperty[] mps, string propName)
        {
            ShaderProperty(me, FindProperty(propName, mps));
        }

        /// <summary>
        /// Draw default item of specified shader property.
        /// </summary>
        /// <param name="me">A <see cref="MaterialEditor"/></param>
        /// <param name="mp">Target <see cref="MaterialProperty"/></param>
        private static void ShaderProperty(MaterialEditor me, MaterialProperty mp)
        {
            me.ShaderProperty(mp, mp.displayName);
        }

        /// <summary>
        /// Draw default texture and color pair.
        /// </summary>
        /// <param name="me">A <see cref="MaterialEditor"/></param>
        /// <param name="mps"><see cref="MaterialProperty"/> array</param>
        /// <param name="propNameTex">Name of shader property of texture</param>
        /// <param name="propNameColor">Name of shader property of color</param>
        private static void TexturePropertySingleLine(MaterialEditor me, MaterialProperty[] mps, string propNameTex, string propNameColor)
        {
            TexturePropertySingleLine(
                me,
                FindProperty(propNameTex, mps),
                FindProperty(propNameColor, mps));
        }

        /// <summary>
        /// Draw default texture and color pair.
        /// </summary>
        /// <param name="me">A <see cref="MaterialEditor"/></param>
        /// <param name="mpTex">Target <see cref="MaterialProperty"/> of texture</param>
        /// <param name="mpColor">Target <see cref="MaterialProperty"/> of color</param>
        private static void TexturePropertySingleLine(MaterialEditor me, MaterialProperty mpTex, MaterialProperty mpColor)
        {
            me.TexturePropertySingleLine(
                new GUIContent(mpTex.displayName, mpColor.displayName),
                mpTex,
                mpColor);
        }

        /// <summary>
        /// Draw default texture and HDR-color pair.
        /// </summary>
        /// <param name="me">A <see cref="MaterialEditor"/></param>
        /// <param name="label">Text label</param>
        /// <param name="toolTipText">Tooltip text</param>
        /// <param name="mps"><see cref="MaterialProperty"/> array</param>
        /// <param name="propNameTex">Name of shader property of texture</param>
        /// <param name="propNameColor">Name of shader property of color</param>
        private static void TextureWithHdrColor(MaterialEditor me, string label, string toolTipText, MaterialProperty[] mps, string propNameTex, string propNameColor)
        {
            TextureWithHdrColor(
                me,
                label,
                toolTipText,
                FindProperty(propNameTex, mps),
                FindProperty(propNameColor, mps));
        }

        /// <summary>
        /// Draw default texture and HDR-color pair.
        /// </summary>
        /// <param name="me">A <see cref="MaterialEditor"/></param>
        /// <param name="label">Text label</param>
        /// <param name="toolTipText">Tooltip text</param>
        /// <param name="mpTex">Target <see cref="MaterialProperty"/> of texture</param>
        /// <param name="mpColor">Target <see cref="MaterialProperty"/> of texture</param>
        private static void TextureWithHdrColor(MaterialEditor me, string label, string toolTipText, MaterialProperty mpTex, MaterialProperty mpColor)
        {
            me.TexturePropertyWithHDRColor(
                new GUIContent(label, toolTipText),
                mpTex,
                mpColor,
#if !UNITY_2018_1_OR_NEWER
                new ColorPickerHDRConfig(
                    minBrightness: 0,
                    maxBrightness: 10,
                    minExposureValue: -10,
                    maxExposureValue: 10),
#endif  // !UNITY_2018_1_OR_NEWER
                showAlpha: false);
        }
    }
}
