//
//  ViewfinderView.swift
//  PhotoCamera
//
//  Created by Manuel Winter on 20.09.25.
//


import SwiftUI
import AVFoundation

struct ViewfinderView: UIViewRepresentable {
    
    let camera: Camera

    func makeUIView(context: Context) -> PreviewView {
        PreviewView(session: camera.captureSession)
    }
    
    func updateUIView(_ previewView: PreviewView, context: Context) {
    }
    
    class PreviewView: UIView {
        
        init(session: AVCaptureSession) {
            super.init(frame: .zero)
#if targetEnvironment(simulator)
            backgroundColor = .gray
#endif
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.session = session
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        private var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
