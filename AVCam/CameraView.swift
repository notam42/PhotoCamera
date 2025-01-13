/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main user interface for the sample app.
*/

import SwiftUI
import AVFoundation
import AVKit


private let viewfinderAspectRatio = CGSize(width: 3, height: 4)
private let viewfinderYOffset = CGFloat(-80 / 2) // half of toolbar height


struct CameraView: View {

    let camera: Camera

    @State private var blink: Bool = false // capture blink effect
    @State private var blurRadius = CGFloat.zero // camera switch blur effect
    @State private var uiImage: UIImage? // result


    var body: some View {
        ZStack {
            // A container view that manages the placement of the preview.
            viewfinderContainer {
                // A view that provides a preview of the captured content.
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                else {
                    ViewfinderView(camera: camera)
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
            }
            .ignoresSafeArea()

            // The main camera user interface.
            cameraUI()
        }

        .task {
            guard !Camera.isPreview else { return }
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

                        case .didCapture(let uiImage):
                            self.uiImage = uiImage

                        case .didImport(let uiImage):
                            self.uiImage = uiImage
                    }
                }
            }
        }
    }

    // MARK: - viewfinder container

    private func viewfinderContainer(@ViewBuilder content: () -> some View) -> some View {
        content()
            .clipped()
            .aspectRatio(viewfinderAspectRatio, contentMode: .fit)
            .offset(y: viewfinderYOffset)
            .blur(radius: blurRadius, opaque: true)
            .onChange(of: camera.isSwitchingModes, updateBlurRadius(_:_:))
            .onChange(of: camera.isSwitchingVideoDevices, updateBlurRadius(_:_:))
    }

    private func updateBlurRadius(_: Bool, _ isSwitching: Bool) {
        withAnimation {
            blurRadius = isSwitching ? 30 : 0
        }
    }

    // MARK: - camera UI

    private func cameraUI() -> some View {
        VStack {
            Spacer()
            MainToolbar(camera: camera)
                .background(.ultraThinMaterial.opacity(0.8))
                .cornerRadius(12)
                .padding(.bottom, 32)
                .padding(.horizontal)
        }
        .overlay {
            StatusOverlayView(status: camera.status)
        }
    }
}

#Preview {
    CameraView(camera: Camera())
}
