/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main user interface for the sample app.
*/

import SwiftUI
import AVKit
import UIKit.UIImage

enum ViewfinderShape {
    case round
    case square
    case rect3x4
    case rect9x16

    var ratio: CGFloat {
        switch self {
            case .round, .square: 1
            case .rect3x4: 3.0 / 4
            case .rect9x16: 9.0 / 16
        }
    }
}

struct CameraView: View {

    @Environment(\.dismiss) private var dismiss

    let camera: Camera
    let viewfinderShape: ViewfinderShape
    let onConfirm: (UIImage?) -> Void

    @State private var blink: Bool = false // capture blink effect
    @State private var blurRadius = CGFloat.zero // camera switch blur effect
    @State private var capturedImage: UIImage? // result


    var body: some View {
        GeometryReader { proxy in
            // A container view that manages the placement of the preview.
            viewfinderContainer(viewSize: proxy.size) {
                // A view that provides a preview of the captured content.
                if let capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                else {
                    ViewfinderView(camera: camera)
                        // Handle capture events from device hardware buttons.
                        .onCameraCaptureEvent { event in
                            if event.phase == .ended {
                                camera.capturePhoto()
                            }
                        }

                        // Focus and expose at the tapped point.
                        .onTapGesture { location in
                            Task { await camera.focusAndExpose(at: location) }
                        }
                        .opacity(blink ? 0 : 1)
                }
            }

            .task {
                guard !Camera.isPreview else { return }
                // Start the capture pipeline.
                await camera.start()
                Task {
                    // Listen to capture events
                    for await activity in camera.activityStream {
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
                                withAnimation(.linear(duration: 0.1)) {
                                    capturedImage = uiImage
                                }

                            case .didImport(let uiImage):
                                withAnimation(.linear(duration: 0.1)) {
                                    capturedImage = uiImage
                                }
                        }
                    }
                }
            }
        }

        .statusBarHidden(true)
        .background(.black)
        .ignoresSafeArea() // order is important
        .overlay {
            cameraUI()
            closeButton()
        }
    }

    private func closeButton() -> some View {
        VStack(alignment: .trailing) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .frame(width: 44, height: 44)
                .foregroundColor(.white)
                .font(.system(size: 28))
                .shadow(color: .black, radius: 3)
                .padding(.horizontal)
            }
            Spacer()
        }
    }

    // MARK: - viewfinder container

    private func viewfinderContainer(viewSize: CGSize, @ViewBuilder content: @escaping () -> some View) -> some View {
        VStack {
            let ratio = viewfinderShape.ratio
            let width = viewSize.width
            let height = width / ratio
            Spacer()
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
                .onChange(of: camera.isSwitchingVideoDevices, updateBlurRadius(_:_:))
            Spacer()
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
            CameraToolbar(camera: camera, showConfirmation: capturedImage != nil) { result in
                if result {
                    dismiss()
                    onConfirm(capturedImage?.cropped(ratio: viewfinderShape.ratio))
                }
                else {
                    capturedImage = nil
                }
            }
            .background(.ultraThinMaterial.opacity(0.3))
            .cornerRadius(12)
            .padding(.bottom, 32)
            .padding(.horizontal)
        }
        .overlay {
            StatusOverlayView(status: camera.status)
        }
    }
}

// MARK: - Previews

#Preview("Round") {
    CameraView(camera: Camera(), viewfinderShape: .round) { _ in }
}

#Preview("Square") {
    CameraView(camera: Camera(), viewfinderShape: .square) { _ in }
}

#Preview("Rect3x4") {
    CameraView(camera: Camera(), viewfinderShape: .rect3x4) { _ in }
}

#Preview("Rect9x16") {
    CameraView(camera: Camera(), viewfinderShape: .rect9x16) { _ in }
}
