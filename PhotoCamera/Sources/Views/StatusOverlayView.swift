//
//  StatusOverlayView.swift
//  PhotoCamera
//
//  Created by Manuel Winter on 20.09.25.
//


import SwiftUI

/// A view that presents a status message over the camera user interface.
struct StatusOverlayView: View {
	
	let status: CameraStatus

	var body: some View {
		if [.unauthorized, .failed].contains(status) {
            ZStack {
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
	}

	private var message: String {
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
    StatusOverlayView(status: .failed)
        .ignoresSafeArea()
}

#Preview("Unauthorized") {
    StatusOverlayView(status: .unauthorized)
        .ignoresSafeArea()
}
