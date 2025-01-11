/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that provides the interface to the features of the camera.
*/

import SwiftUI

/// An object that provides the interface to the features of the camera.
///
@Observable
@MainActor
final class Camera {
    
    /// The current status of the camera, such as unauthorized, running, or failed.
    private(set) var status = CameraStatus.unknown

    /// A Boolean value that indicates whether the app is currently switching video devices.
    private(set) var isSwitchingVideoDevices = false

    /// A Boolean value that indicates whether the app is currently switching capture modes.
    private(set) var isSwitchingModes = false
    
    /// A Boolean value that indicates whether to show visual feedback when capture begins.
    private(set) var shouldFlashScreen = false
    
    /// A thumbnail for the last captured photo or video.
    private(set) var thumbnail: CGImage?
    
    /// An error that indicates the details of an error during photo or movie capture.
    private(set) var error: Error?
    
    /// An object that provides the connection between the capture session and the video preview layer.
    var previewSource: PreviewSource { captureService.previewSource }
    
    /// An object that manages the app's capture functionality.
    private let captureService = CaptureService()

    init(status: CameraStatus = .unknown) {
        self.status = status
    }

    // MARK: - Starting the camera
    /// Start the camera and begin the stream of data.
    func start() async {
        guard !Self.isPreview else {
            status = .running
            return
        }

        // Verify that the person authorizes the app to use device cameras.
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        do {
            // Start the capture service to start the flow of data.
            try await captureService.start()
            observeState()
            status = .running
        } catch {
            logger.error("Failed to start capture service. \(error)")
            status = .failed
        }
    }
    
    // MARK: - Changing devices

    /// Selects the next available video device for capture.
    func switchVideoDevices() async {
        guard !Self.isPreview else { return }
        isSwitchingVideoDevices = true
        defer { isSwitchingVideoDevices = false }
        await captureService.selectNextVideoDevice()
    }
    
    // MARK: - Photo capture
    
    /// Captures a photo and writes it to the user's Photos library.
    func capturePhoto() async {
        guard !Self.isPreview else { return }
        logger.info("Photo captured")
        let _ = try? await captureService.capturePhoto()
        // TODO:
    }

    /// Performs a focus and expose operation at the specified screen point.
    func focusAndExpose(at point: CGPoint) async {
        guard !Self.isPreview else { return }
        await captureService.focusAndExpose(at: point)
    }
    
    /// Sets the `showCaptureFeedback` state to indicate that capture is underway.
    private func flashScreen() {
        shouldFlashScreen = true
        withAnimation(.linear(duration: 0.01)) {
            shouldFlashScreen = false
        }
    }

    // MARK: - Internal state observations
    
    // Set up camera's state observations.
    private func observeState() {
        Task {
            // Await new capture activity values from the capture service.
            for await activity in await captureService.$captureActivity.values {
                if activity == .willCapture {
                    // Flash the screen to indicate capture is starting.
                    flashScreen()
                }
            }
        }
    }

    private static let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}
