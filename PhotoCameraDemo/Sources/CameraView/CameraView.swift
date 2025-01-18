/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main user interface for the sample app.
*/

import SwiftUI
import AVKit
import UIKit.UIImage
import PhotoCamera

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

    let viewfinderShape: ViewfinderShape
    let onConfirm: (UIImage?) -> Void

    @State private var camera: Camera
    @State private var blink: Bool = false // capture blink effect
    @State private var blurRadius = CGFloat.zero // camera switch blur effect
    @State private var capturedImage: UIImage? // result


    init(forSelfie: Bool, viewfinderShape: ViewfinderShape, onConfirm: @escaping (UIImage?) -> Void) {
        self.camera = Camera(forSelfie: forSelfie)
        self.viewfinderShape = viewfinderShape
        self.onConfirm = onConfirm
    }


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
            .frame(maxWidth: .infinity)

            .task {
                guard !Camera.isPreview else { return }
                // Start the capture pipeline.
                await camera.start()
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
                            
                        @unknown default:
                            fatalError()
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
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .frame(width: 44, height: 44)
                .foregroundColor(.white)
                .font(.system(size: 28))
                .shadow(color: .black.opacity(0.5), radius: 3)
                .padding(8)
                Spacer()
            }
            Spacer()
        }
    }

    // MARK: - viewfinder container

    private func viewfinderContainer(viewSize: CGSize, @ViewBuilder content: @escaping () -> some View) -> some View {
        VStack {
            let ratio = viewfinderShape.ratio
            let viewRatio = viewSize.width / viewSize.height
            let landscape = viewRatio > ratio
            let is916 = viewfinderShape == .rect9x16
            let pad = is916 ? 0 : 16.0
            let width = max(0, (landscape ? viewSize.height * ratio : viewSize.width) - pad * 2)
            let height = max(0, (landscape ? viewSize.height : viewSize.width / ratio) - pad * 2)
            if viewfinderShape != .rect9x16 {
                Spacer()
            }
            content()
                .aspectRatio(ratio, contentMode: .fill)
                .frame(width: width, height: height)
                .blur(radius: blurRadius, opaque: true)
                .overlay {
                    if viewfinderShape == .round {
                        holeMask(width: width, height: height)
                            .allowsHitTesting(false) // allow user-initiated focus/exposure taps
                    }
                }
                .clipped()
                .offset(y: viewfinderYOffset(landscape: landscape))
                .onChange(of: camera.isSwitchingVideoDevices, updateBlurRadius(_:_:))
            if viewfinderShape != .rect9x16 {
                Spacer()
            }
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

    private func viewfinderYOffset(landscape: Bool) -> CGFloat {
        // Move smaller viewfinders up a little bit, only in portrait mode
        !landscape && [.round, .square, .rect3x4].contains(viewfinderShape) ? -80.0 / 2 : 0
    }

    private func updateBlurRadius(_: Bool, _ isSwitching: Bool) {
        withAnimation {
            blurRadius = isSwitching ? 30 : 0
        }
    }

    // MARK: - camera UI

    private func cameraUI() -> some View {
        GeometryReader { proxy in
            let viewRatio = proxy.size.width / proxy.size.height
            let landscape = viewRatio > viewfinderShape.ratio
            stack(vertical: !landscape) {
                Spacer()
                stack(vertical: landscape) {
                    Spacer()
                    CameraToolbar(vertical: landscape, camera: camera, showConfirmation: capturedImage != nil) { result in
                        if result {
                            dismiss()
                            onConfirm(capturedImage?.cropped(ratio: viewfinderShape.ratio))
                        }
                        else {
                            capturedImage = nil
                        }
                    }
                    Spacer()
                }
                .padding(landscape ? .trailing : .bottom, 28)
            }
            .overlay {
                StatusOverlayView(status: camera.status)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Previews

#Preview("Round") {
    CameraView(forSelfie: true, viewfinderShape: .round) { _ in }
}

#Preview("Square") {
    CameraView(forSelfie: true, viewfinderShape: .square) { _ in }
}

#Preview("Rect3x4") {
    CameraView(forSelfie: true, viewfinderShape: .rect3x4) { _ in }
}

#Preview("Rect9x16") {
    CameraView(forSelfie: true, viewfinderShape: .rect9x16) { _ in }
}
