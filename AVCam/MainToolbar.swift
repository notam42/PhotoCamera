/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 A view that displays controls to capture, switch cameras, and view the last captured media item.
 */

import SwiftUI
import PhotosUI

private let largeButtonSize = CGSize(width: 64, height: 64)
private let toolbarHeight = 80.0


// MARK: - Toolbar

/// A view that displays controls to capture, switch cameras, and view the last captured media item.
struct MainToolbar: View {

    let camera: Camera

    var body: some View {
        HStack {
            PhotoPickerButton(camera: camera)
            Spacer()
            CaptureButton(camera: camera)
            Spacer()
            SwitchCameraButton(camera: camera)
        }
        .foregroundColor(.white)
        .font(.system(size: 24))
        .frame(height: toolbarHeight)
        .padding(.horizontal)
    }
}

// MARK: - Photo picker button

/// A view that displays a button to select a photo from the library.
private struct PhotoPickerButton: View {

    let camera: Camera
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
            Image(systemName: "photo.on.rectangle")
        }
        .frame(width: largeButtonSize.width, height: largeButtonSize.height)
        .onChange(of: selectedItem) {
            if let selectedItem {
                Task {
                    if let data = try? await selectedItem.loadTransferable(type: Data.self) {
                        camera.importImage(data: data)
                    }
                }
            }
        }
    }
}

// MARK: - Switch camera button

/// A view that displays a button to switch between available cameras.
private struct SwitchCameraButton: View {

    let camera: Camera

    var body: some View {
        Button {
            Task {
                await camera.switchVideoDevices()
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
        .frame(width: largeButtonSize.width, height: largeButtonSize.height)
        .allowsHitTesting(!camera.isSwitchingVideoDevices)
    }
}

// MARK: - Capture button

/// A view that displays an appropriate capture button for the selected mode.
private struct CaptureButton: View {

    let camera: Camera

    private let mainButtonDimension: CGFloat = 68

    var body: some View {
        PhotoCaptureButton {
            Task {
                await camera.capturePhoto()
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
        .frame(width: mainButtonDimension)
    }
}

private struct PhotoCaptureButton: View {
    let action: () -> Void
    private let lineWidth = CGFloat(4.0)

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .fill(.white)
            Button {
                action()
            } label: {
                Circle()
                    .inset(by: lineWidth * 1.2)
                    .fill(.white)
            }
            .buttonStyle(PhotoButtonStyle())
        }
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

#Preview {
    Group {
        MainToolbar(camera: Camera())
    }
}
