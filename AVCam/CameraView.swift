/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main user interface for the sample app.
*/

import SwiftUI
import AVFoundation
import AVKit

@MainActor
struct CameraView: PlatformView {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: Camera

    var body: some View {
        ZStack {
            // A container view that manages the placement of the preview.
            PreviewContainer(camera: camera) {
                // A view that provides a preview of the captured content.
                CameraPreview(source: camera.previewSource)
                    // Handle capture events from device hardware buttons.
                    .onCameraCaptureEvent { event in
                        if event.phase == .ended {
                            Task {
                                // Capture a photo when pressing a hardware button.
                                await camera.capturePhoto()
                            }
                        }
                    }
                    // Focus and expose at the tapped point.
                    .onTapGesture { location in
                        Task { await camera.focusAndExpose(at: location) }
                    }
                    /// The value of `shouldFlashScreen` changes briefly to `true` when capture
                    /// starts, and then immediately changes to `false`. Use this change to
                    /// flash the screen to provide visual feedback when capturing photos.
//                    .opacity(camera.shouldFlashScreen ? 0 : 1)
            }
            // The main camera user interface.
            CameraUI(camera: camera)
        }
    }
}

#Preview {
    CameraView(camera: Camera())
}
