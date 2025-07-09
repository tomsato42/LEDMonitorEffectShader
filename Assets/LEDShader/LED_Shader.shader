Shader "Custom/LED_Shader_URP"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaskTex ("Mask Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "Queue" = "Geometry"
        }
        LOD 100

        Pass
        {
            Name "Unlit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex); // 保持しておくだけ、今は使わない

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            float calc_tile_uv(Varyings IN, float total_width, float total_height)
            {
                float2 uv_in_tile;
                uv_in_tile.x = frac(IN.uv.x * total_width);
                uv_in_tile.y = frac(IN.uv.y * total_height);
                
                float2 delta = uv_in_tile - 0.5;
                float dist = length(delta) * 2.0;
                dist = saturate(dist);

                return dist;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                const float scale = 0.125;
                float total_width = 640.0 * 3.0 * scale;
                float total_height = 480.0 * scale;

                total_width += total_width % 3.0;
                total_height += total_width % 2.0;

                float tile_u = 1.0 / total_width;
                float tile_v = 1.0 / total_height;

                int tile_index_u = (int)floor(IN.uv.x / tile_u);
                int tile_index_v = (int)floor(IN.uv.y / tile_v);

                float2 snapped_uv;
                snapped_uv.x = (tile_index_u + 0.5) * tile_u;
                snapped_uv.y = (tile_index_v + 0.5) * tile_v;

                half4 maintex_color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, snapped_uv);

                int mask_index_u = tile_index_u % 3;
                
                float local_u = frac(IN.uv.x * total_width);
                float local_v = frac(IN.uv.y * total_height);
                half2 mask_uv = half2(local_u, local_v);
                if (mask_uv.x < 0.2 || 0.8 < mask_uv.x || 
                    mask_uv.y < 0.2 || 0.8 < mask_uv.y)
                {
                    return half4(0,0,0,1); // 端のUVは無視
                }

                float blend = 1.0 -  calc_tile_uv(IN, total_width, total_height);;
                half4 masktex_color = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, mask_uv) * 4.0;

                half3 base_color;
                if (mask_index_u == 0)
                    base_color = half3(masktex_color.r, 0.0, 0.0);
                else if (mask_index_u == 1)
                    base_color = half3(0.0, masktex_color.g, 0.0);
                else
                    base_color = half3(0.0, 0.0, masktex_color.b);
                half3 white_boost = blend * masktex_color.rgb * 0.05;
                base_color += white_boost;
                base_color = saturate(base_color);

                return maintex_color * half4(base_color, 1.0);
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/InternalErrorShader"
}