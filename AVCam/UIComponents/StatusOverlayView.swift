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
		if [.unauthorized, .failed, .interrupted].contains(status) {
			// Dimming view.
			Rectangle()
				.fill(Color(white: 0.0, opacity: 0.5))
			// Status message.
			Text(message)
				.font(.headline)
                .foregroundColor(color == .yellow ? .init(white: 0.25) : .white)
				.padding()
				.background(color)
				.cornerRadius(8.0)
                .padding(16)
                .frame(maxWidth: 600)
		}
	}
	
	var color: Color {
		switch status {
		case .unauthorized:
			return .red
		case .failed:
			return .orange
		case .interrupted:
			return .yellow
		default:
			return .clear
		}
	}
	
	var message: String {
		switch status {
		case .unauthorized:
			return "You haven't authorized the app to use the camera. Change these settings in Settings → Privacy & Security"
		case .interrupted:
			return "The camera was interrupted by higher-priority media processing."
		case .failed:
			return "The camera failed to start. Please try relaunching the app."
		default:
			return ""
		}
	}
}

#Preview("Interrupted") {
    CameraView(camera: Camera(status: .interrupted))
}

#Preview("Failed") {
    CameraView(camera: Camera(status: .failed))
}

#Preview("Unauthorized") {
    CameraView(camera: Camera(status: .unauthorized))
}
