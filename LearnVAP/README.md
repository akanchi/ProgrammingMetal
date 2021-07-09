* [VAP](https://github.com/Tencent/vap)渲染视频的部分代码。<br>
* [AlphaPlayer](https://github.com/bytedance/AlphaPlayer)，字节的这个库渲染和vap差不多，只是vap多了mp4解析和融合动画？


#### AlphaPlayer的fragmentFunction

```
fragment float4 samplingShader(RasterizerData input [[stage_in]],
               texture2d<float> textureY [[ texture(BDAlphaPlayerFragmentTextureIndexTextureY) ]],
               texture2d<float> textureUV [[ texture(BDAlphaPlayerFragmentTextureIndexTextureUV) ]],
               constant BDAlphaPlayerConvertMatrix *convertMatrix [[ buffer(BDAlphaPlayerFragmentInputIndexMatrix) ]])
{
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    
    float tcx = input.textureCoordinate.x / 2 + 0.5;
    
    float3 yuv = float3(textureY.sample(textureSampler, float2(tcx, input.textureCoordinate.y)).r,
                          textureUV.sample(textureSampler, float2(tcx, input.textureCoordinate.y)).rg);
    
    float3 rgb = convertMatrix->matrix * (yuv + convertMatrix->offset);
    
    float3 alpha = float3(textureY.sample(textureSampler, float2(input.textureCoordinate.x / 2, input.textureCoordinate.y)).r,
    textureUV.sample(textureSampler, float2(input.textureCoordinate.x / 2, input.textureCoordinate.y)).rg);
        
    float3 alphargb = convertMatrix->matrix * (alpha + convertMatrix->offset);
    return float4(rgb, alphargb.r);
}
```
alpha通道只能在原视频的左边
