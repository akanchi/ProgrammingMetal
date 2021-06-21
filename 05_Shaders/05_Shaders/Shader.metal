//
//  Shader.metal
//  03_Triangles
//
//  Created by akanchi on 2021/6/20.
//

#include <metal_stdlib>
using namespace metal;

struct Constants {
    float animateBy;
};

struct VertexIn {
    float4 position [[ attribute(0) ]];
    float4 color [[ attribute(1) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float4 color;
};

vertex VertexOut vertex_shader(const VertexIn vertexIn [[ stage_in ]]) {
    VertexOut vertexOut;
    vertexOut.position = vertexIn.position;
    vertexOut.color = vertexIn.color;

    return vertexOut;
}

fragment half4 fragment_shader(VertexOut vertexIn [[ stage_in ]]) {
    float grayColor = (vertexIn.color.r + vertexIn.color.g + vertexIn.color.b)/3;

    return half4(grayColor, grayColor, grayColor, 1);
}
