/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that provides the interface to the features of the camera.
*/

@preconcurrency import AVFoundation
import UIKit.UIImage

enum CameraStatus {
    case unknown
    case unauthorized
    case failed
    case running
}

/// An object that provides the interface to the features of the camera.
///
@Observable
@MainActor
final class Camera {

    /// The app's capture session.
    var captureSession: AVCaptureSession { captureService.captureSession }

    /// The activity stream for indicating capture stages
    var activityStream: AsyncStream<CaptureActivity> { captureService.activityStream }

    /// The current status of the camera, such as unauthorized, running, or failed.
    private(set) var status = CameraStatus.unknown

    /// A Boolean value that indicates whether the app is currently switching video devices.
    private(set) var isSwitchingVideoDevices = false

    /// An object that manages the app's capture functionality.
    private let captureService: CaptureService

    init(forSelfie: Bool = false) {
        self.captureService = CaptureService(forSelfie: forSelfie)
    }

    init(status: CameraStatus) { // for previews only
        self.status = status
        self.captureService = CaptureService(forSelfie: false)
    }

    // MARK: - Starting the camera
    /// Start the camera and begin the stream of data.
    func start() async {
        guard !Self.isPreview else { return }

        // Verify that the person authorizes the app to use device cameras.
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        do {
            // Start the capture service to start the flow of data.
            try await captureService.start()
            status = .running
        } catch {
            print("Failed to start capture service. \(error)")
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
    
    /// Captures a photo
    func capturePhoto() {
        guard !Self.isPreview else { return }
        Task {
            // Note: even though the below call is async, it doesn't wait for completion of the capture. Use `activityStream` to monitor events in your UI.
            await captureService.capturePhoto()
        }
    }

    /// Performs a focus and expose operation at the specified screen point.
    func focusAndExpose(at point: CGPoint) async {
        guard !Self.isPreview else { return }
        await captureService.focusAndExpose(at: point)
    }

    // MARK: - Import image and pass it via the stream

    func importImage(data: Data) {
        captureService.activityContinuation.yield(.didImport(uiImage: UIImage(data: data)))
    }

    static let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}
