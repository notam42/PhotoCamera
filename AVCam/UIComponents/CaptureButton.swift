/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays an appropriate capture button for the selected capture mode.
*/

import SwiftUI

/// A view that displays an appropriate capture button for the selected mode.
struct CaptureButton: View {
    
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

#Preview("Photo") {
    CaptureButton(camera: Camera())
}
