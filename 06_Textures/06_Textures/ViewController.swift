//
//  ViewController.swift
//  02_GettingStarted
//
//  Created by akanchi on 2021/6/19.
//

import UIKit
import MetalKit

// @see: https://www.youtube.com/watch?v=Gqj2lP7qlAM&list=PL23Revp-82LJG3vcDPm8w7b5HTKjBOY0W&index=2

enum Colors {
    static let wenderlichGreen = MTLClearColor(red: 0, green: 0.4, blue: 0.21, alpha: 1)
}

class ViewController: UIViewController {

    var metalView: MTKView {
        return view as! MTKView
    }

    var renderer: Renderer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // create a reference to the GPU
        metalView.device = MTLCreateSystemDefaultDevice()
        renderer = Renderer(device: metalView.device!)

        metalView.clearColor = Colors.wenderlichGreen
        metalView.delegate = renderer
    }
}
