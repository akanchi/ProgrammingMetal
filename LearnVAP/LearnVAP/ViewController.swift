//
//  ViewController.swift
//  LearnVAP
//
//  Created by akanchi on 2021/7/4.
//

import UIKit
import MetalKit

class ViewController: UIViewController {

    @IBOutlet weak var mtkView: MTKView!
    var renderer: Renderer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // create a reference to the GPU
        mtkView.device = MTLCreateSystemDefaultDevice()
        renderer = Renderer(device: mtkView.device!)

        mtkView.preferredFramesPerSecond = 25
        mtkView.delegate = renderer
    }
}

