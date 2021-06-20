//
//  Shader.metal
//  03_Triangles
//
//  Created by akanchi on 2021/6/20.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 vertex_shader(const device packed_float3 *vertices [[ buffer(0) ]],
                            uint vertexId [[ vertex_id ]]) {
    return float4(vertices[vertexId], 1);
}

fragment half4 fragment_shader() {
    return half4(1, 1, 0, 1); // yellow
//    return half4(1, 0, 0, 1); // red
}
