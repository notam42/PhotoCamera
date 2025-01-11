/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents a video preview of the captured content.
*/

import SwiftUI
@preconcurrency import AVFoundation

struct CameraPreview: UIViewRepresentable {
    
    let camera: Camera

    func makeUIView(context: Context) -> PreviewView {
        let preview = PreviewView(session: camera.captureSession)
        // Connect the preview layer to the capture session.
        return preview
    }
    
    func updateUIView(_ previewView: PreviewView, context: Context) {
        // No-op.
    }
    
    /// A class that presents the captured content.
    ///
    /// This class owns the `AVCaptureVideoPreviewLayer` that presents the captured content.
    ///
    class PreviewView: UIView {
        
        init(session: AVCaptureSession) {
            super.init(frame: .zero)
    #if targetEnvironment(simulator)
            // The capture APIs require running on a real device. If running
            // in Simulator, display a static image to represent the video feed.
            let imageView = UIImageView(frame: UIScreen.main.bounds)
            imageView.image = UIImage(named: "photo_mode")
            imageView.contentMode = .scaleAspectFill
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(imageView)
    #endif
            previewLayer.session = session
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // Use the preview layer as the view's backing layer.
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        private var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
