Shader "Custom/B-SplineInterpolatedTexture"
{
    Properties
    {
        [Toggle(ENABLE_FILTERING)] _EnableFiltering("Enable B-Spline Filtering", Float) = 0
        _MainTex ("Texture", 2D) = "white" {}
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

            #pragma multi_compile _ ENABLE_FILTERING

            #include "UnityCG.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };


            // Samplers etc.
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float4 _MainTex_ST;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }


            // Efficient GPU-Based Texture Interpolation using Uniform B-Splines.
            // http://mate.tue.nl/mate/pdfs/10318.pdf
            // Based on the source code presented in the paper.
            // Ported by Olli S.
            // NOTE, IMPORTANT:
            // This shader requires the texture to be filtered with bilinear filtering. It does not work with nearest neighbor.
            fixed4 Interpolate_Bicubic(sampler2D tex, float2 uv)
            {
                // transform the coordinate from [0,extent] to [-0.5, extent-0.5].
                // Scale coordinates to to pixel size, offset half pixel.
                float2 coord_grid = uv.xy * _MainTex_TexelSize.zw - 0.5;

                // Generate 2D index from pixel coordinates by flooring the values to nearest integer.
                float2 index = floor(coord_grid);
                float2 fraction = coord_grid - index;
                float2 one_frac = 1.0 - fraction;
                float2 one_frac2 = one_frac * one_frac;
                float2 fraction2 = fraction * fraction;
                float2 w0 = 1.0 / 6.0 * one_frac2 * one_frac;
                float2 w1 = 2.0 / 3.0 - 0.5 * fraction2 * (2.0 - fraction);
                float2 w2 = 2.0 / 3.0 - 0.5 * one_frac2 * (2.0 - one_frac);
                float2 w3 = 1.0 / 6.0 * fraction2 * fraction;
                float2 g0 = w0 + w1;
                float2 g1 = w2 + w3;

                // h0 = w1/g0 - 1, move from [-0.5, extent-0.5] to [0, extent].
                float2 h0 = (w1 / g0) + index - 0.5;
                float2 h1 = (w3 / g1) + index + 1.5;

                // Scale the coordinates back to 0-1 UV range for sampling.
                h0 /= _MainTex_TexelSize.zw;
                h1 /= _MainTex_TexelSize.zw;

                // fetch the four linear interpolations.
                float4 tex00 = tex2D(tex, float2(h0.x, h0.y));
                float4 tex10 = tex2D(tex, float2(h1.x, h0.y));
                float4 tex01 = tex2D(tex, float2(h0.x, h1.y));
                float4 tex11 = tex2D(tex, float2(h1.x, h1.y));

                // weigh along the y-direction.
                tex00 = lerp(tex01, tex00, g0.y);
                tex10 = lerp(tex11, tex10, g0.y);

                // weigh along the x-direction.
                return lerp(tex10, tex00, g0.x);
            }            


            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture.
                #ifdef ENABLE_FILTERING
                    fixed4 col = Interpolate_Bicubic(_MainTex, i.uv);
                #else
                    fixed4 col = tex2D(_MainTex, i.uv);
                #endif

                // apply fog.
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }

            ENDCG
        }
    }
}
