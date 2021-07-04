//
//  Shader.metal
//  LearnVAP
//
//  Created by akanchi on 2021/7/4.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    float4 clipSpacePostion [[ position ]];
    float2 textureColorCoordinate;
    float2 textureAlphaCoordinate;
} VAPRasterizerData;

typedef struct {
    packed_float4 position;
    packed_float2 textureColorCoordinate;
    packed_float2 textureAlphaCoordinate;
} QGVAPVertex;

struct ColorParameters {
    float3x3 matrix;
    packed_float2 offset;
};

vertex VAPRasterizerData vap_vertexShader(uint vertexID [[ vertex_id ]], constant QGVAPVertex *vertexArray [[ buffer(0) ]]) {

    VAPRasterizerData out;
    out.clipSpacePostion = vertexArray[vertexID].position;
    out.textureColorCoordinate = vertexArray[vertexID].textureColorCoordinate;
    out.textureAlphaCoordinate = vertexArray[vertexID].textureAlphaCoordinate;
    return out;
}

float3 RGBColorFromYuvTextures(sampler textureSampler, float2 coordinate, texture2d<float> texture_luma, texture2d<float> texture_chroma, float3x3 rotationMatrix, float2 offset) {

    float3 color;
    color.x = texture_luma.sample(textureSampler, coordinate).r;
    color.yz = texture_chroma.sample(textureSampler, coordinate).rg - offset;
    return float3(rotationMatrix * color);
}

float4 RGBAColor(sampler textureSampler, float2 colorCoordinate, float2 alphaCoordinate, texture2d<float> lumaTexture, texture2d<float> chromaTexture, constant ColorParameters *colorParameters) {
    float3x3 rotationMatrix = colorParameters[0].matrix;
    float2 offset = colorParameters[0].offset;
    float3 color = RGBColorFromYuvTextures(textureSampler, colorCoordinate, lumaTexture, chromaTexture, rotationMatrix, offset);
    float3 alpha = RGBColorFromYuvTextures(textureSampler, alphaCoordinate, lumaTexture, chromaTexture, rotationMatrix, offset);
    return float4(color, alpha.r);
}

fragment float4 vap_yuvFragmentShader(VAPRasterizerData input [[ stage_in ]],
                                      texture2d<float>  lumaTexture [[ texture(0) ]],
                                      texture2d<float>  chromaTexture [[ texture(1) ]],
                                      constant ColorParameters *colorParameters [[ buffer(0) ]]) {
    //signifies that an expression may be computed at compile-time rather than runtime
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    return RGBAColor(textureSampler, input.textureColorCoordinate, input.textureAlphaCoordinate, lumaTexture, chromaTexture, colorParameters);
}

