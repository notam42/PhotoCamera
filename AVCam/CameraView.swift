/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main user interface for the sample app.
*/

import SwiftUI
import AVFoundation
import AVKit


struct CameraView: View {

    enum ViewfinderShape {
        case round
        case square
        case rect3x4
        case rect9x16
        case fullScreen
    }

    let camera: Camera
    let viewfinderShape: ViewfinderShape

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

    private func viewfinderContainer(@ViewBuilder content: @escaping () -> some View) -> some View {
        GeometryReader { proxy in
            VStack {
                let ratio = aspectRatioFromShape()
                let width = proxy.size.width
                let height = ratio.map { width / $0 } ?? proxy.size.height
                if ratio != nil {
                    Spacer()
                }
                content()
                    .aspectRatio(ratio, contentMode: .fill)
                    .frame(width: width, height: height)
                    .blur(radius: blurRadius, opaque: true)
                    .overlay {
                        if viewfinderShape == .round {
                            holeMask(width: width, height: height)
                        }
                    }
                    .clipped()
                    .offset(y: viewfinderYOffset())
                    .onChange(of: camera.isSwitchingModes, updateBlurRadius(_:_:))
                    .onChange(of: camera.isSwitchingVideoDevices, updateBlurRadius(_:_:))
                if ratio != nil {
                    Spacer()
                }
            }
        }
    }

    private func aspectRatioFromShape() -> CGFloat? {
        switch viewfinderShape {
            case .round, .square: 1
            case .rect3x4: 3 / 4
            case .rect9x16: 9 / 16
            case .fullScreen: nil
        }
    }

    private func holeMask(width: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .fill(.black)
            .mask(
                HoleShapeMask(CGRect(x: 0, y: 0, width: width, height: height), in: CGRect(x: 0, y: 0, width: width, height: height))
                    .fill(style: .init(eoFill: true))
            )
    }

    private func HoleShapeMask(_ hole: CGRect, in rect: CGRect) -> Path {
        var shape = Rectangle().path(in: rect)
        shape.addPath(Circle().path(in: hole))
        return shape
    }

    private func viewfinderYOffset() -> CGFloat {
        [.round, .square, .rect3x4].contains(viewfinderShape) ? -80.0 / 2 : 0
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

#Preview("Round") {
    CameraView(camera: Camera(), viewfinderShape: .round)
}

#Preview("Square") {
    CameraView(camera: Camera(), viewfinderShape: .square)
}

#Preview("Rect3x4") {
    CameraView(camera: Camera(), viewfinderShape: .rect3x4)
}

#Preview("Rect9x16") {
    CameraView(camera: Camera(), viewfinderShape: .rect9x16)
}

#Preview("Full screen") {
    CameraView(camera: Camera(), viewfinderShape: .fullScreen)
}
