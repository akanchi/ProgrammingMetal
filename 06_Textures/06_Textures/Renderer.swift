//
//  Renderer.swift
//  02_GettingStarted
//
//  Created by akanchi on 2021/6/19.
//

import UIKit
import MetalKit

class Renderer: NSObject {
    struct Vertex {
        var position: SIMD3<Float>
        var color: SIMD4<Float>
        var texture: SIMD2<Float>
    }

    var vertices: [Vertex] = [
        Vertex(position: SIMD3<Float>(-1, 1, 0), color: SIMD4<Float>(1, 0, 0, 1), texture: SIMD2<Float>(0, 1)),
        Vertex(position: SIMD3<Float>(-1, -1, 0), color: SIMD4<Float>(0, 1, 0, 1), texture: SIMD2<Float>(0, 0)),
        Vertex(position: SIMD3<Float>(1, -1, 0), color: SIMD4<Float>(0, 0, 1, 1), texture: SIMD2<Float>(1, 0)),
        Vertex(position: SIMD3<Float>(1, 1, 0), color: SIMD4<Float>(1, 0, 1, 1), texture: SIMD2<Float>(1, 1)),
//        -1,  1, 0, // V0
//        -1, -1, 0, // V1
//         1,  1, 0, // V2
//         1, -1, 0, // V3
    ]

    var indices: [UInt16] = [
//        0, 1, 2, 3
        0, 1, 2,
        2, 3, 0
    ]

    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!

    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?

    struct Constants {
        var animateBy: Float = 0.0
    }

    var constants = Constants()

    var time: Float = 0

    var samplerState: MTLSamplerState?
    var texture: MTLTexture?

    convenience init(device: MTLDevice) {
        self.init()

        self.device = device
        self.commandQueue = device.makeCommandQueue()

//        buildSampleState()
        buildTexture()
        buildModel()
        bulidPipelineState()
    }

    private func buildTexture() {
        let textureLoader = MTKTextureLoader.init(device: device)
        let textureLoaderOptions = [MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.bottomLeft]
        if let textureURL = Bundle.main.url(forResource: "avatar", withExtension: "jpeg") {
            do {
                try texture = textureLoader.newTexture(URL: textureURL, options: textureLoaderOptions)
            } catch {
                print("texture not created")
            }
        }
    }

    private func buildSampleState() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.mipFilter = .linear
        self.samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }

    private func buildModel() {
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])
        indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.size, options: [])
    }

    private func bulidPipelineState() {
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_shader")

        var fragmentFunctionName = "fragment_shader"
        if let _ = self.texture {
            fragmentFunctionName = "textured_fragment"
        }

        let fragmentFunction = library?.makeFunction(name: fragmentFunctionName)

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD4<Float>>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride

        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        do {
            pipelineState =  try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    }

    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let pipelineState = self.pipelineState,
              let indexBuffer = self.indexBuffer,
              let drawable = view.currentDrawable
        else {
            return
        }

        let commandBuffer = commandQueue.makeCommandBuffer()

        time += 1/Float(view.preferredFramesPerSecond)

        let animateBy = abs(sin(time) + 0.5)
        constants.animateBy = animateBy

        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
//        commandEncoder?.setFragmentSamplerState(samplerState, index: 0)
        commandEncoder?.setRenderPipelineState(pipelineState)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.setVertexBytes(&constants, length: MemoryLayout<Constants>.stride, index: 1)
        commandEncoder?.setFragmentTexture(texture, index: 0)
//        commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        commandEncoder?.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
