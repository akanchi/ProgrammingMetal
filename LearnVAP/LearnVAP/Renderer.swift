//
//  Renderer.swift
//  LearnVAP
//
//  Created by akanchi on 2021/7/4.
//

import UIKit
import MetalKit

class Renderer: NSObject {
    struct QGVAPVertex {
        var position: simd_packed_float4
        var textureColorCoordinate: simd_packed_float2
        var textureAlphaCoordinate: simd_packed_float2
    }

    struct ColorParameters {
        var matrix: simd_float3x3
        var offset: simd_packed_float2
    }

    let kVAPMTLVerticesIdentity: [Float] = [-1.0, -1.0, 0.0, 1.0, -1.0, 1.0, 0.0, 1.0, 1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0]

    let kColorConversionMatrix601FullRangeDefault: simd_float3x3 = simd_float3x3([
        SIMD3<Float>(1.0, 1.0, 1.0),
        SIMD3<Float>(0.0, -0.34413, 1.772),
        SIMD3<Float>(1.402, -0.71414, 0.0),
    ])

    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!

    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var yuvMatrixBuffer: MTLBuffer?
    private var reader: AssetReader = AssetReader(url: Bundle.main.url(forResource: "demo", withExtension: "mp4")!)
    private var videoTextureCache: CVMetalTextureCache?

    convenience init(device: MTLDevice) {
        self.init()

        self.device = device
        self.commandQueue = device.makeCommandQueue()

        buildModel()
        bulidYUVMatrix()
        bulidPipelineState()
        reader.startProcessing()
    }

    private func bulidYUVMatrix() {
        let yuvMatrixs: [ColorParameters] = [ColorParameters(matrix: kColorConversionMatrix601FullRangeDefault, offset: simd_packed_float2(0.5, 0.5))]

        self.yuvMatrixBuffer = self.device.makeBuffer(bytes: yuvMatrixs, length: yuvMatrixs.count * MemoryLayout<ColorParameters>.stride, options: .storageModeShared)

        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, self.device, nil, &videoTextureCache)
    }

    func genMTLTextureCoordinates(rect: CGRect, containerSize: CGSize) -> [CGFloat] {
        let originX = rect.origin.x / containerSize.width
        let originY = rect.origin.y / containerSize.height
        let width = rect.size.width / containerSize.width
        let height = rect.size.height / containerSize.height
        let tempCoordintes = [originX, originY+height, originX, originY, originX+width, originY+height, originX+width, originY]
        return tempCoordintes
    }

    private func buildModel() {
        //顶点(x,y,z,w),纹理坐标(x,x),数组长度
        let colunmCountForVertices = 4
        let colunmCountForCoordinate = 2

        let rgbCoordinates: [CGFloat] = genMTLTextureCoordinates(rect: CGRect(x: 4, y: 4, width: 736, height: 576), containerSize: CGSize(width: 752, height: 880))
        let alphaCoordinates: [CGFloat] = genMTLTextureCoordinates(rect: CGRect(x: 4, y: 588, width: 368, height: 288), containerSize: CGSize(width: 752, height: 880))

        var vertexData: [Float] = []

        // kVAPMTLVerticesIdentity 顶点坐标图示, []里面是序号
//        [1](-1, 1) ---  (1, 1) [3]
//         |                      |
//         |                      |
//        [0](-1, -1) --- (1, -1)[2]
        // genMTLTextureCoordinates 里面生成纹理坐标, 左上角是（originX, originY）
        // 下面的方法是将顶点坐标和纹理坐标对应上
        for i in 0..<4*colunmCountForVertices {
            vertexData.append(kVAPMTLVerticesIdentity[i])

            if i % colunmCountForVertices == (colunmCountForVertices-1) {
                let row = i/colunmCountForVertices
                vertexData.append(Float(rgbCoordinates[row * colunmCountForCoordinate]))
                vertexData.append(Float(rgbCoordinates[row * colunmCountForCoordinate + 1]))
                vertexData.append(Float(alphaCoordinates[row * colunmCountForCoordinate]))
                vertexData.append(Float(alphaCoordinates[row * colunmCountForCoordinate + 1]))
            }
        }

        vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.stride, options: [])
    }

    private func bulidPipelineState() {
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vap_vertexShader")
        let fragmentFunction = library?.makeFunction(name: "vap_yuvFragmentShader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        // 启用Blend
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceColor
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceColor

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
        guard let pipelineState = self.pipelineState,
              let drawable = view.currentDrawable,
              let buffer = reader.readBuffer()?.imageBuffer,
              let videoTextureCache = self.videoTextureCache
        else {
            return
        }

        CVMetalTextureCacheFlush(videoTextureCache, 0)
        var yTextureRef: CVMetalTexture?
        var uvTextureRef: CVMetalTexture?
        let yWidth = CVPixelBufferGetWidthOfPlane(buffer, 0)
        let yHeight = CVPixelBufferGetHeightOfPlane(buffer, 0)
        let uvWidth = CVPixelBufferGetWidthOfPlane(buffer, 1)
        let uvHeight = CVPixelBufferGetHeightOfPlane(buffer, 1)
        let yStatus = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTextureCache, buffer, nil, .r8Unorm, yWidth, yHeight, 0, &yTextureRef)
        let uvStatus = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTextureCache, buffer, nil, .rg8Unorm, uvWidth, uvHeight, 1, &uvTextureRef)
        if yStatus != kCVReturnSuccess || uvStatus != kCVReturnSuccess {
            return
        }

        guard let yTexture = CVMetalTextureGetTexture(yTextureRef!) else { return }
        guard let uvTexture = CVMetalTextureGetTexture(uvTextureRef!) else { return }

        CVMetalTextureCacheFlush(videoTextureCache, .zero)

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

        commandEncoder?.setRenderPipelineState(pipelineState)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.setFragmentBuffer(self.yuvMatrixBuffer, offset: 0, index: 0)
        commandEncoder?.setFragmentTexture(yTexture, index: 0)
        commandEncoder?.setFragmentTexture(uvTexture, index: 1)
        commandEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
