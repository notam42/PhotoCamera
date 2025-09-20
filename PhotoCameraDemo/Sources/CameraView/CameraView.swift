//
//  CameraView.swift
//
//  Created by Hovik Melikyan on 15.01.25.
//

import SwiftUI
import AVKit
import UIKit.UIImage
import PhotoCamera
import PhotosUI

private let largeButtonSize = CGSize(width: 64, height: 64)
private let toolbarHeight = 88.0
private let maxToolbarWidth = 360.0
private let captureButtonDimension = 68.0

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss

    private let title: String?
    private let isRound: Bool
    private let onConfirm: (UIImage?) -> Void

    @State private var camera: Camera
    @State private var blink: Bool = false // capture blink effect
    @State private var blurRadius = CGFloat.zero // camera switch blur effect
    @State private var capturedImage: UIImage? // result
    @State private var libraryItem: PhotosPickerItem?

    init(title: String?, forSelfie: Bool, isRound: Bool, onConfirm: @escaping (UIImage?) -> Void) {
		self.title = title
        self.camera = Camera(forSelfie: forSelfie)
        self.isRound = isRound
        self.onConfirm = onConfirm
    }

    var body: some View {
        GeometryReader { proxy in
            // A container view that manages the placement of the preview.
            viewfinderContainer(viewSize: proxy.size) {
                ViewfinderView(camera: camera)
                    // Handle capture events from device hardware buttons.
                    .onCameraCaptureEvent { event in
                        if event.phase == .ended {
                            capturePhoto()
                        }
                    }

                    // Focus and expose at the tapped point.
                    .onTapGesture { location in
                        Task { await camera.focusAndExpose(at: location) }
                    }
                    .opacity(blink ? 0 : 1)

                    // A view that provides a preview of the captured content.
                    .overlay {
                        // This is done as an overlay because hiding and showing the video layer (ViewfinderView above) without restarting the session causes strange problems on macOS, though is fine on the iPhone.
                        if let capturedImage {
                            Image(uiImage: capturedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
            }
            .frame(maxWidth: .infinity)

            .task {
                await camera.start()
            }
        }
        .padding(.vertical, title == nil ? 0 : 60) // make room for the title if present

        .statusBarHidden(true)
        .background(.black)
        .ignoresSafeArea() // order is important
        .overlay {
            closeButton()
            if let title {
                VStack {
                    Text(title)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(12)
                    Spacer()
                }
            }
            cameraUI()
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
                .font(.system(size: 24))
                .shadow(color: .black.opacity(0.5), radius: 3)
                .padding(8)
                Spacer()
            }
            Spacer()
        }
    }

    // MARK: - Internal capture photo method

    private func capturePhoto() {
        Task {
            // "Blink" the viewfinder as if it's the shutter
            withAnimation(.linear(duration: 0.05)) {
                blink = true
            } completion: {
                withAnimation(.linear(duration: 0.05)) {
                    blink = false
                }
            }

            // Do capture
            capturedImage = try? await camera.capturePhoto()
        }
    }

    // MARK: - viewfinder container

    private func viewfinderContainer(viewSize: CGSize, @ViewBuilder content: @escaping () -> some View) -> some View {
        VStack {
            let width = max(0, min(viewSize.width, viewSize.height) - 16 * 2)
            let height = width
            Spacer()
            content()
                .aspectRatio(1.0, contentMode: .fill)
                .frame(width: width, height: height)
                .blur(radius: blurRadius, opaque: true)
                .overlay {
                    if isRound {
                        holeMask(width: width, height: height)
                            .allowsHitTesting(false) // allow user-initiated focus/exposure taps
                    }
                }
                .clipped()
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

    private func updateBlurRadius(_: Bool, _ isSwitching: Bool) {
        withAnimation {
            blurRadius = isSwitching ? 30 : 0
        }
    }

    // MARK: - camera UI

    private func cameraUI() -> some View {
        GeometryReader { proxy in
            let landscape = proxy.size.width > proxy.size.height
            stack(vertical: !landscape) {
                Spacer()
                stack(vertical: landscape) {
                    Spacer()
                    cameraToolbar(vertical: landscape)
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

    // MARK: - Toolbar

    private func cameraToolbar(vertical: Bool) -> some View {
        stack(vertical: vertical) {
            if capturedImage != nil {
                retryButton()
                Spacer()
                confirmButton()
            }
            else {
                photoPickerButton()
                Spacer()
                captureButton()
                Spacer()
                switchCameraButton()
            }
        }
        .foregroundColor(.white)
        .font(.system(size: 24, weight: .medium))
        .frame(width: vertical ? toolbarHeight : nil, height: vertical ? nil : toolbarHeight)
        .padding(vertical ? .vertical : .horizontal, 16)
        .background(.ultraThinMaterial.opacity(0.3))
        .cornerRadius(12)
        .frame(maxWidth: vertical ? nil : maxToolbarWidth, maxHeight: vertical ? maxToolbarWidth : nil)
    }

    // MARK: - Confirm buttons

    private func confirmButton() -> some View {
        Button {
            dismiss()
            onConfirm(capturedImage?.cropped(ratio: 1))
        } label: {
            Image(systemName: "checkmark")
        }
        .frame(width: largeButtonSize.width, height: largeButtonSize.height)
    }

    private func retryButton() -> some View {
        Button {
            capturedImage = nil
        } label: {
            Image(systemName: "arrow.uturn.left")
        }
        .frame(width: largeButtonSize.width, height: largeButtonSize.height)
    }

    // MARK: - Photo picker button

    private func photoPickerButton() -> some View {
        PhotosPicker(selection: $libraryItem, matching: .images, photoLibrary: .shared()) {
            Image(systemName: "photo.on.rectangle")
        }
        .frame(width: largeButtonSize.width, height: largeButtonSize.height)
        .onChange(of: libraryItem) {
            if let libraryItem {
                Task {
                    if let data = try? await libraryItem.loadTransferable(type: Data.self) {
                        capturedImage = UIImage(data: data)
                    }
                }
            }
            libraryItem = nil
        }
    }

    // MARK: - Switch camera button

    private func switchCameraButton() -> some View {
        Button {
            Task {
                await camera.switchVideoDevices()
            }
        } label: {
            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.camera")
        }
        .frame(width: largeButtonSize.width, height: largeButtonSize.height)
        .disabled(camera.isSwitchingVideoDevices)
    }

    // MARK: - Capture button

    private func captureButton() -> some View {
        ZStack {
            let lineWidth = 4.0
            Circle()
                .stroke(lineWidth: lineWidth)
                .fill(.white)
            Button {
                capturePhoto()
            } label: {
                Circle()
                    .inset(by: lineWidth * 1.2)
                    .fill(.white)
            }
            .buttonStyle(PhotoButtonStyle())
        }
        .frame(width: captureButtonDimension)
    }

    private struct PhotoButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

// MARK: - View.stack() extension

private extension View {
    @ViewBuilder
    func stack<Content: View>(vertical: Bool, @ViewBuilder content: () -> Content) -> some View {
        if vertical {
            VStack(spacing: 0, content: content)
        }
        else {
            HStack(spacing: 0, content: content)
        }
    }
}


// MARK: - Previews

#Preview("Round") {
    CameraView(title: "Take a selfie", forSelfie: true, isRound: true) { _ in }
}

#Preview("Square") {
    CameraView(title: "Take a selfie", forSelfie: true, isRound: false) { _ in }
}
