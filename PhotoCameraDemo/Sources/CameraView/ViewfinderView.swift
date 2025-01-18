/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents a video preview of the captured content.
*/

import SwiftUI
import AVFoundation
import PhotoCamera

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
