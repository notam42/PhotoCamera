/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that provides the interface to the features of the camera.
*/

@preconcurrency import AVFoundation
import UIKit.UIImage

public enum CameraStatus {
    case unknown
    case unauthorized
    case failed
    case running
}

/// An object that provides the interface to the features of the camera.
///
@Observable
@MainActor
public final class Camera {

    /// The app's capture session.
    public var captureSession: AVCaptureSession { captureService.captureSession }

    /// The activity stream for indicating capture stages
    public var activityStream: AsyncStream<CaptureActivity> { captureService.activityStream }

    /// The current status of the camera, such as unauthorized, running, or failed.
    public private(set) var status = CameraStatus.unknown

    /// A Boolean value that indicates whether the app is currently switching video devices.
    public private(set) var isSwitchingVideoDevices = false

    /// An object that manages the app's capture functionality.
    private let captureService: CaptureService

    public init(forSelfie: Bool = false) {
        self.captureService = CaptureService(forSelfie: forSelfie)
    }

    init(status: CameraStatus) { // for previews only
        self.status = status
        self.captureService = CaptureService(forSelfie: false)
    }

    // MARK: - Authorization
    /// A Boolean value that indicates whether a person authorizes this app to use
    /// device cameras. If they haven't previously authorized the app, querying this
    /// property prompts them for authorization.
    public static var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            var isAuthorized = status == .authorized
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            return isAuthorized
        }
    }

    // MARK: - Starting the camera
    /// Start the camera and begin the stream of data.
    public func start() async {
        guard !Self.isPreview else { return }

        // Verify that the person authorizes the app to use device cameras.
        guard await Self.isAuthorized else {
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
    public func switchVideoDevices() async {
        guard !Self.isPreview else { return }
        isSwitchingVideoDevices = true
        defer { isSwitchingVideoDevices = false }
        await captureService.selectNextVideoDevice()
    }
    
    // MARK: - Photo capture
    
    /// Captures a photo
    public func capturePhoto() {
        guard !Self.isPreview else { return }
        Task {
            // Note: even though the below call is async, it doesn't wait for completion of the capture. Use `activityStream` to monitor events in your UI.
            await captureService.capturePhoto()
        }
    }

    /// Performs a focus and expose operation at the specified screen point.
    public func focusAndExpose(at point: CGPoint) async {
        guard !Self.isPreview else { return }
        await captureService.focusAndExpose(at: point)
    }

    // MARK: - Import image and pass it via the stream

    public func importImage(data: Data) {
        captureService.activityContinuation.yield(.didImport(uiImage: UIImage(data: data)))
    }

    public static let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}
