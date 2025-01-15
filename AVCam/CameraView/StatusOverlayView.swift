/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents a status message over the camera user interface.
*/

import SwiftUI

/// A view that presents a status message over the camera user interface.
struct StatusOverlayView: View {
	
	let status: CameraStatus

	var body: some View {
		if [.unauthorized, .failed].contains(status) {
			// Dimming view.
			Rectangle()
				.fill(Color(white: 0.0, opacity: 0.5))
			// Status message.
			Text(message)
				.font(.headline)
                .foregroundColor(.white)
				.padding()
                .background(.ultraThinMaterial)
				.cornerRadius(8.0)
                .padding(16)
                .frame(maxWidth: 600)
		}
	}

	var message: String {
        switch status {
            case .unauthorized:
                "You haven't authorized the app to use the camera. Change these settings in Settings → Privacy & Security"
            case .failed:
                "The camera failed to start. Please try relaunching the app."
            default:
                ""
        }
	}
}

#Preview("Failed") {
    CameraView(camera: Camera(status: .failed), viewfinderShape: .rect3x4) { _ in }
}

#Preview("Unauthorized") {
    CameraView(camera: Camera(status: .unauthorized), viewfinderShape: .fullScreen) { _ in }
}
