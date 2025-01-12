/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main user interface for the sample app.
*/

import SwiftUI
import AVFoundation
import AVKit

struct CameraView: View {

    let camera: Camera

    @State private var blink: Bool = false
    @State private var photoData: Data?


    var body: some View {
        ZStack {
            // A container view that manages the placement of the preview.
            PreviewContainer(camera: camera) {
                // A view that provides a preview of the captured content.
                CameraPreview(camera: camera)
                    // Handle capture events from device hardware buttons.
                    .onCameraCaptureEvent { event in
                        if event.phase == .ended {
                            Task {
                                await camera.capturePhoto()
                            }
                        }
                    }

                    // Focus and expose at the tapped point.
                    .onTapGesture { location in
                        Task { await camera.focusAndExpose(at: location) }
                    }
                    .opacity(blink ? 0 : 1)
            }

            // The main camera user interface.
            CameraUI(camera: camera)
        }

        .task {
            // Start the capture pipeline.
            await camera.start()
            Task {
                // Listen to capture events
                for await activity in camera.activityStream {
                    print("Activity: \(activity)")
                    switch activity {
                        case .willCapture:
                            withAnimation(.linear(duration: 0.05)) {
                                blink = true
                            } completion: {
                                withAnimation(.linear(duration: 0.05)) {
                                    blink = false
                                }
                            }
                        case .didCapture(let data):
                            photoData = data
                    }
                }
            }
        }
    }
}

#Preview {
    CameraView(camera: Camera())
}
