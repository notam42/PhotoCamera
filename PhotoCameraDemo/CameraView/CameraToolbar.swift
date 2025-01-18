/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 A view that displays controls to capture, switch cameras, and view the last captured media item.
 */

import SwiftUI
import UIKit.UIImage
import PhotosUI

private let largeButtonSize = CGSize(width: 64, height: 64)
private let toolbarHeight = 88.0
private let maxToolbarWidth = 360.0
private let captureButtonDimension = 68.0


// MARK: - Toolbar

/// A view that displays controls to capture, switch cameras, and view the last captured media item.
struct CameraToolbar: View {

    let vertical: Bool
    let camera: Camera
    let showConfirmation: Bool
    let onDone: (Bool) -> Void

    @State private var libraryItem: PhotosPickerItem?

    var body: some View {
        stack(vertical: vertical) {
            if showConfirmation {
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
        .background(.ultraThinMaterial.opacity(0.4))
        .cornerRadius(12)
        .frame(maxWidth: vertical ? nil : maxToolbarWidth, maxHeight: vertical ? maxToolbarWidth : nil)
    }

    // MARK: - Confirm buttons

    private func confirmButton() -> some View {
        Button {
            onDone(true)
        } label: {
            Image(systemName: "checkmark")
        }
        .frame(width: largeButtonSize.width, height: largeButtonSize.height)
    }

    private func retryButton() -> some View {
        Button {
            onDone(false)
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
                        camera.importImage(data: data)
                    }
                }
            }
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
                camera.capturePhoto()
            } label: {
                Circle()
                    .inset(by: lineWidth * 1.2)
                    .fill(.white)
            }
            .buttonStyle(PhotoButtonStyle())
        }
        .frame(width: captureButtonDimension)
    }

    struct PhotoButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

extension View {
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

// MARK: - Preview

#Preview("Capture - Portrait") {
    CameraToolbar(vertical: false, camera: Camera(), showConfirmation: false) { _ in }
        .background(.black)
}

#Preview("Preview - Portrait") {
    CameraToolbar(vertical: false, camera: Camera(), showConfirmation: true) { _ in }
        .background(.black)
}

#Preview("Capture - Landscape") {
    CameraToolbar(vertical: true, camera: Camera(), showConfirmation: false) { _ in }
        .background(.black)
}

#Preview("Preview - Landscape") {
    CameraToolbar(vertical: true, camera: Camera(), showConfirmation: true) { _ in }
        .background(.black)
}
