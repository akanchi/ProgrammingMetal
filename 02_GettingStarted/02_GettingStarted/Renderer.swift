//
//  Renderer.swift
//  02_GettingStarted
//
//  Created by akanchi on 2021/6/19.
//

import UIKit
import MetalKit

class Renderer: NSObject {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!

    convenience init(device: MTLDevice) {
        self.init()

        self.device = device
        self.commandQueue = device.makeCommandQueue()
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    }

    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable
        else {
            return
        }

        let commandBuffer = commandQueue.makeCommandBuffer()

        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
