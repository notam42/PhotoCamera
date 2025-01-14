/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 A view that displays controls to capture, switch cameras, and view the last captured media item.
 */

import SwiftUI
import UIKit.UIImage
import PhotosUI

private let largeButtonSize = CGSize(width: 64, height: 64)
private let toolbarHeight = 80.0
private let captureButtonDimension = 68.0


// MARK: - Toolbar

/// A view that displays controls to capture, switch cameras, and view the last captured media item.
struct CameraToolbar: View {

    let camera: Camera
    @Binding var capturedImage: UIImage?
    let onConfirm: (UIImage?) -> Void

    @State private var libraryItem: PhotosPickerItem?

    var body: some View {
        HStack {
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
        .font(.system(size: 28, weight: .semibold))
        .frame(height: toolbarHeight)
        .padding(.horizontal)
    }

    // MARK: - Confirm buttons

    private func confirmButton() -> some View {
        Button {
            onConfirm(capturedImage)
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
        .allowsHitTesting(!camera.isSwitchingVideoDevices)
    }

    // MARK: - Capture button

    private func captureButton() -> some View {
        ZStack {
            let lineWidth = 4.0
            Circle()
                .stroke(lineWidth: lineWidth)
                .fill(.white)
            Button {
                Task {
                    await camera.capturePhoto()
                }
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

// MARK: - Preview

#Preview("Capture") {
    Group {
        CameraToolbar(camera: Camera(), capturedImage: .constant(nil)) { _ in }
    }
}

#Preview("Preview") {
    Group {
        CameraToolbar(camera: Camera(), capturedImage: .constant(UIImage())) { _ in }
    }
}
