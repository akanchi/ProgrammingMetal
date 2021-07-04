//
//  AssetReader.swift
//  LearnVAP
//
//  Created by akanchi on 2021/7/4.
//

import UIKit
import AVFoundation

class AssetReader: NSObject {
    private var reader: AVAssetReader?
    private var keepLooping: Bool = true
    private var url: URL!
    private var readerVideoTrackOutput: AVAssetReaderTrackOutput?
    private var lock: NSLock!

    convenience init(url: URL) {
        self.init()

        self.lock = NSLock()
        self.url = url
    }

    override init() {
        super.init()
    }

    func startProcessing() {
        let inputAsset: AVURLAsset = AVURLAsset(url: self.url, options: nil)
        inputAsset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            DispatchQueue.global(qos: .default).async { [weak self] () in
                let tracksStatus = inputAsset.statusOfValue(forKey: "tracks", error: nil)
                if tracksStatus != .loaded {
                    return;
                }

                self?.processAsset(asset: inputAsset)
            }
        }
    }

    func processAsset(asset: AVURLAsset) {
        self.lock.lock()
        do {
            self.reader = try AVAssetReader(asset: asset)
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }

        let outputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
        self.readerVideoTrackOutput = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: .video).first!, outputSettings: outputSettings)
        self.readerVideoTrackOutput?.alwaysCopiesSampleData = false
        self.reader?.add(self.readerVideoTrackOutput!)

        self.reader?.startReading()

        self.lock.unlock()
    }

    func readBuffer() -> CMSampleBuffer? {
        self.lock.lock()
        var ret: CMSampleBuffer?
        if let output = self.readerVideoTrackOutput {
            ret = output.copyNextSampleBuffer()
        }

        if let reader = self.reader, reader.status == .completed {
            self.readerVideoTrackOutput = nil
            self.reader = nil
            self.startProcessing()
        }

        self.lock.unlock()

        return ret
    }
}
