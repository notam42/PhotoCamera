//
//  CaptureService.swift
//
//  Created by Hovik Melikyan on 15.01.25.
//

import Foundation
import Combine
@preconcurrency import AVFoundation
import UIKit.UIImage

public enum CameraError: Error {
    case videoDeviceUnavailable
    case addInputFailed
    case addOutputFailed
    case setupFailed
    case deviceChangeFailed
    case photoCaptureFailed
    case zoomOperationFailed
}

/// An actor that manages the capture pipeline, which includes the capture session, device inputs, and capture outputs.
/// The app defines it as an `actor` type to ensure that all camera operations happen off of the `@MainActor`.
actor CaptureService {

    /// The app's capture session.
    nonisolated let captureSession = AVCaptureSession()

    /// The capture output type for this service.
    private let output = AVCapturePhotoOutput()

    /// Whether to use the front camera first
    private let forSelfie: Bool
    
    /// The current zoom level of the camera
    private(set) var currentZoomFactor: CGFloat = 1.0
    
    /// The maximum zoom level allowed (capped at 10.0)
    private let maxZoomFactor: CGFloat = 10.0
    
    /// Available zoom factors provided by the device
    private var availableZoomFactors: [CGFloat] = []

    /// Available optical zoom factors provided by the device
    private var availableOpticalZoomFactors: [CGFloat] = []
  
    /// The video input for the currently selected device camera.
    private var activeVideoInput: AVCaptureDeviceInput?

    /// An object the service uses to retrieve capture devices.
    private let deviceLookup = DeviceLookup()

    /// An object that monitors video device rotations.
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator!
    private var rotationObservers = [AnyObject]()

    /// A Boolean value that indicates whether the actor finished its required configuration.
    private var isSetUp = false

    /// A serial dispatch queue to use for capture control actions.
    private let sessionQueue = DispatchSerialQueue(label: "eu.manuelwinter.CameraView")

    /// Cancel the async notification loops using this collection; internal.
    private var cancellables = Set<AnyCancellable>()

    /// In addition to `cancelables`, subject area change notifications should be reset every time an input device is changed.
    private var subjectAreaChangeTask: Task<Void, Never>?

    /// Sets the session queue as the actor's executor.
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }

    init(forSelfie: Bool) {
        self.forSelfie = forSelfie
    }

    // MARK: - Capture session life cycle
    func start() async throws {
        // Exit early if not authorized or the session is already running.
        guard !captureSession.isRunning else { return }
        // Configure the session and start it.
        try setUpSession()
        captureSession.startRunning()
    }

    // MARK: - Capture setup
    // Performs the initial capture session configuration.
    private func setUpSession() throws {
        // Return early if already set up.
        guard !isSetUp else { return }

        // Observe internal state and notifications.
        observeNotifications()

        do {
            // Retrieve the default camera
            let defaultCamera = try deviceLookup.defaultCamera(forSelfie: forSelfie)

            // Add inputs for the default camera devices.
            activeVideoInput = try addInput(for: defaultCamera)

            // Configure the session preset based on the current capture mode.
            captureSession.sessionPreset = .photo
            // Add the photo capture output as the default output type.
            try addOutput(output)

            // Configure a rotation coordinator for the default video device.
            createRotationCoordinator(for: defaultCamera)
            // Observe changes to the default camera's subject area.
            observeSubjectAreaChanges(of: defaultCamera)
            // Update the service's advertised capabilities.
            updateCaptureCapabilities()

            isSetUp = true
        } catch {
            throw CameraError.setupFailed
        }
    }

    // Adds an input to the capture session to connect the specified capture device.
    @discardableResult
    private func addInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        let input = try AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            throw CameraError.addInputFailed
        }
        return input
    }

    // Adds an output to the capture session to connect the specified capture device, if allowed.
    private func addOutput(_ output: AVCaptureOutput) throws {
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        } else {
            throw CameraError.addOutputFailed
        }
    }

    // The device for the active video input.
    private var currentDevice: AVCaptureDevice {
        guard let device = activeVideoInput?.device else {
            fatalError("No device found for current video input.")
        }
        return device
    }

    // MARK: - Device selection

    /// Changes the capture device that provides video input.
    ///
    /// The app calls this method in response to the user tapping the button in the UI to change cameras.
    /// The implementation switches between the front and back cameras and, in iPadOS,
    /// connected external cameras.
    func selectNextVideoDevice() {
        // The array of available video capture devices.
        let videoDevices = deviceLookup.cameras

        // Find the index of the currently selected video device.
        let selectedIndex = videoDevices.firstIndex(of: currentDevice) ?? 0
        // Get the next index.
        var nextIndex = selectedIndex + 1
        // Wrap around if the next index is invalid.
        if nextIndex == videoDevices.endIndex {
            nextIndex = 0
        }

        let nextDevice = videoDevices[nextIndex]
        // Change the session's active capture device.
        changeCaptureDevice(to: nextDevice)

        // The app only calls this method in response to the user requesting to switch cameras.
        // Set the new selection as the user's preferred camera.
        AVCaptureDevice.userPreferredCamera = nextDevice
    }

    // Changes the device the service uses for video capture.
    private func changeCaptureDevice(to device: AVCaptureDevice) {
        // The service must have a valid video input prior to calling this method.
        guard let currentInput = activeVideoInput else { fatalError() }

        // Bracket the following configuration in a begin/commit configuration pair.
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        // Remove the existing video input before attempting to connect a new one.
        captureSession.removeInput(currentInput)
        do {
            // Attempt to connect a new input and device to the capture session.
            activeVideoInput = try addInput(for: device)
            // Configure a new rotation coordinator for the new device.
            createRotationCoordinator(for: device)
            // Register for device observations.
            observeSubjectAreaChanges(of: device)
            // Update the service's advertised capabilities.
            updateCaptureCapabilities()
        } catch {
            // Reconnect the existing camera on failure.
            captureSession.addInput(currentInput)
        }
    }

    // MARK: - Rotation handling

    /// Create a new rotation coordinator for the specified device and observe its state to monitor rotation changes.
    private func createRotationCoordinator(for device: AVCaptureDevice) {
        // Somehow this function doesn't work correctly on the Mac, apparently it doesn't need rotation correction. Plus it doesn't need to since it's a Mac.
        guard !ProcessInfo.processInfo.isiOSAppOnMac else { return }

        // Create a new rotation coordinator for this device.
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: videoPreviewLayer)

        // Set initial rotation state on the preview and output connections.
        updatePreviewRotation(rotationCoordinator.videoRotationAngleForHorizonLevelPreview)
        updateCaptureRotation(rotationCoordinator.videoRotationAngleForHorizonLevelCapture)

        // Cancel previous observations.
        rotationObservers.removeAll()

        // Add observers to monitor future changes.
        rotationObservers.append(
            rotationCoordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { [weak self] _, change in
                guard let self, let angle = change.newValue else { return }
                // Update the capture preview rotation.
                Task { await self.updatePreviewRotation(angle) }
            }
        )

        rotationObservers.append(
            rotationCoordinator.observe(\.videoRotationAngleForHorizonLevelCapture, options: .new) { [weak self] _, change in
                guard let self, let angle = change.newValue else { return }
                // Update the capture preview rotation.
                Task { await self.updateCaptureRotation(angle) }
            }
        )
    }

    private func updatePreviewRotation(_ angle: CGFloat) {
      videoPreviewLayer.connection?.videoRotationAngle = angle
//        let previewLayer = videoPreviewLayer
//        Task { @MainActor in
//            // Set initial rotation angle on the video preview.
//            previewLayer.connection?.videoRotationAngle = angle
//        }
    }

    private func updateCaptureRotation(_ angle: CGFloat) {
        // Set the rotation angle on the output object's video connection.
        output.connection(with: .video)?.videoRotationAngle = angle
    }

    private var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // Access the capture session's connected preview layer.
        guard let previewLayer = captureSession.connections.compactMap({ $0.videoPreviewLayer }).first else {
            fatalError("The app is misconfigured. The capture session should have a connection to a preview layer.")
        }
        return previewLayer
    }

    // MARK: - Automatic focus and exposure

    /// Performs a one-time automatic focus and expose operation.
    ///
    /// The app calls this method as the result of a person tapping on the preview area.
    func focusAndExpose(at point: CGPoint) {
        // The point this call receives is in view-space coordinates. Convert this point to device coordinates.
        let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: point)
        // Perform a user-initiated focus and expose.
        try? focusAndExpose(at: devicePoint, isUserInitiated: true)
    }

    // Observe notifications of type `subjectAreaDidChangeNotification` for the specified device.
    private func observeSubjectAreaChanges(of device: AVCaptureDevice) {
        // Cancel the previous observation task.
        subjectAreaChangeTask?.cancel()
        let task = Task { [weak self] in
            // Signal true when this notification occurs.
            for await _ in NotificationCenter.default.notifications(named: AVCaptureDevice.subjectAreaDidChangeNotification, object: device).compactMap({ _ in true }) {
                guard let self else { return }
                // Perform a system-initiated focus and expose.
                try? await focusAndExpose(at: CGPoint(x: 0.5, y: 0.5), isUserInitiated: false)
            }
        }
        subjectAreaChangeTask = task
        AnyCancellable {
            task.cancel()
        }.store(in: &cancellables)
    }

    private func focusAndExpose(at devicePoint: CGPoint, isUserInitiated: Bool) throws {
        // Configure the current device.
        let device = currentDevice

        // The following mode and point of interest configuration requires obtaining an exclusive lock on the device.
        try device.lockForConfiguration()

        let focusMode = isUserInitiated ? AVCaptureDevice.FocusMode.autoFocus : .continuousAutoFocus
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
            device.focusPointOfInterest = devicePoint
            device.focusMode = focusMode
        }

        let exposureMode = isUserInitiated ? AVCaptureDevice.ExposureMode.autoExpose : .continuousAutoExposure
        if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
            device.exposurePointOfInterest = devicePoint
            device.exposureMode = exposureMode
        }
        // Enable subject-area change monitoring when performing a user-initiated automatic focus and exposure operation.
        // If this method enables change monitoring, when the device's subject area changes, the app calls this method a
        // second time and resets the device to continuous automatic focus and exposure.
        device.isSubjectAreaChangeMonitoringEnabled = isUserInitiated

        // Release the lock.
        device.unlockForConfiguration()
    }

    // MARK: - Internal state management
    /// Updates the state of the actor to ensure its advertised capabilities are accurate.
    ///
    /// When the capture session changes, such as changing modes or input devices, the service
    /// calls this method to update its configuration and capabilities. The app uses this state to
    /// determine which features to enable in the user interface.
    private func updateCaptureCapabilities() {
        output.maxPhotoDimensions = currentDevice.activeFormat.supportedMaxPhotoDimensions.last ?? CMVideoDimensions()
        output.maxPhotoQualityPrioritization = .quality
        output.isResponsiveCaptureEnabled = output.isResponsiveCaptureSupported
        output.isFastCapturePrioritizationEnabled = output.isFastCapturePrioritizationSupported
        
        // Update zoom capabilities for the current device
        updateZoomCapabilities()
        updateOpticalZoomCapabilities()
    }

    /// Observe capture-related notifications.
    private func observeNotifications() {
        let task = Task { [weak self] in
            for await error in NotificationCenter.default.notifications(named: AVCaptureSession.runtimeErrorNotification)
                .compactMap({ $0.userInfo?[AVCaptureSessionErrorKey] as? AVError }) {
                // If the system resets media services, the capture session stops running.
                if error.code == .mediaServicesWereReset {
                    guard let self else { return }
                    if !captureSession.isRunning {
                        captureSession.startRunning()
                    }
                }
            }
        }
        AnyCancellable {
            task.cancel()
        }.store(in: &cancellables)
    }

    // MARK: - Photo capture

    func capturePhoto() async throws -> UIImage {
        // Create a new settings object to configure the photo capture.
        var photoSettings = AVCapturePhotoSettings()

        // Capture photos in HEIF format when the device supports it.
        if output.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }

        // Set the format of the preview image to capture. The `photoSettings` object returns the available
        // preview format types in order of compatibility with the primary image.
        if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
        }

        // Set the largest dimensions that the photo output supports.
        // `CaptureService` automatically updates the photo output's `maxPhotoDimensions`
        // when the capture pipeline changes.
        photoSettings.maxPhotoDimensions = output.maxPhotoDimensions

        // Capture a new photo with the specified settings.
        // The below continuation ensures that `delegate` is retained until the captured data is returned
        let delegate = PhotoCaptureDelegate(output: output, settings: photoSettings)
        return try await withCheckedThrowingContinuation { continuation in
            delegate.capturePhoto(with: continuation)
        }
    }
    
    // MARK: - Zoom handling
    
    /// Updates the available zoom factors based on the current device's capabilities.
    /// This method is called when changing devices to ensure zoom capabilities are always up-to-date.
    private func updateZoomCapabilities() {
        let device = currentDevice
        
        // Reset current zoom factor when changing devices
        currentZoomFactor = 1.0
        
        // Get the device's zoom capabilities
        var zoomFactors = [CGFloat]()
        
        // Always add 1.0 as the default zoom level
        zoomFactors.append(1.0)
        
        // Check for optical zoom levels (if available)
        if #available(iOS 15.0, *) {
            // On newer iOS devices, we can get the supported zoom factors directly
          //TODO: Later call updateOpticalZoomCapabilities()
            zoomFactors.append(contentsOf: device.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat(truncating: $0) })
        }
        
        // Get the maximum zoom supported by the device, capped at our maxZoomFactor
        let deviceMaxZoom = min(device.activeFormat.videoMaxZoomFactor, maxZoomFactor)
        
        // Add some standard zoom levels if they don't exceed the maximum
        let standardZoomLevels: [CGFloat] = [2.0, 3.0, 5.0, 8.0, 10.0]
        for level in standardZoomLevels where level <= deviceMaxZoom {
            if !zoomFactors.contains(level) {
                zoomFactors.append(level)
            }
        }
        
        // Sort the zoom factors in ascending order
        zoomFactors.sort()
        
        // Store the available zoom factors
        self.availableZoomFactors = zoomFactors
    }
  
  /// Updates the available zoom factors based on the current device's capabilities.
  /// This method is called when changing devices to ensure zoom capabilities are always up-to-date.
  private func updateOpticalZoomCapabilities() {
      let device = currentDevice
      var opticalZoomFactors = [CGFloat]()

      // Always add 1.0 as the base optical level
      opticalZoomFactors.append(1.0)

      // For ultra-wide camera (0.5x)
      if device.hasUltraWideCamera {
          opticalZoomFactors.append(0.5)
      }

      if #available(iOS 15.0, *) {
          // Get the optical zoom levels from the device's switch-over points
          let switchOverFactors = device.virtualDeviceSwitchOverVideoZoomFactors.map {
              CGFloat(truncating: $0)
          }
          
          // Only add zoom factors that aren't already included
          for factor in switchOverFactors {
              if !opticalZoomFactors.contains(factor) {
                  opticalZoomFactors.append(factor)
              }
          }
      } else {
          // For older iOS versions, check if telephoto is available (usually 2x)
          if device.hasTelephotoCamera {
              opticalZoomFactors.append(2.0)
          }
      }

      // Sort the zoom factors in ascending order
      opticalZoomFactors.sort()
      
      // Store the available optical zoom factors
      self.availableOpticalZoomFactors = opticalZoomFactors
  }
    
    // MARK: - Zoom control
    
    /// Returns all available zoom factors for the current device.
    /// These zoom factors can be used to provide preset zoom options in the UI.
    var zoomFactors: [CGFloat] {
        return availableZoomFactors
    }
  
  /// Returns all available zoom factors for the current device.
  /// These zoom factors can be used to provide preset zoom options in the UI.
  var opticalZoomFactors: [CGFloat] {
      return availableOpticalZoomFactors
  }
    
    /// Sets the camera zoom to the specified factor.
    /// - Parameter factor: The zoom factor to set. If the factor is outside the available range,
    ///   it will be clamped to the nearest valid zoom level.
    /// - Throws: `CameraError.zoomOperationFailed` if the zoom operation failed.
    func setZoomFactor(_ factor: CGFloat) throws {
        let device = currentDevice
        
        // Clamp the zoom factor to the valid range
        let minZoom: CGFloat = 1.0
        let maxDeviceZoom = min(device.activeFormat.videoMaxZoomFactor, maxZoomFactor)
        let targetZoom = clamp(factor, to: minZoom...maxDeviceZoom)
        
        do {
            try device.lockForConfiguration()
            
            // Set the zoom factor
            device.videoZoomFactor = targetZoom
            currentZoomFactor = targetZoom
            
            device.unlockForConfiguration()
        } catch {
            throw CameraError.zoomOperationFailed
        }
    }
    
    /// Increases the zoom level to the next available zoom factor.
    /// - Throws: `CameraError.zoomOperationFailed` if the zoom operation fails.
    func zoomIn() throws {
        guard !availableZoomFactors.isEmpty else { return }
        
        // Find the next higher zoom factor
        let nextZoom = availableZoomFactors.first { $0 > currentZoomFactor } ?? currentZoomFactor
        
        // If we're already at max zoom, do nothing
        if nextZoom == currentZoomFactor { return }
        
        try setZoomFactor(nextZoom)
    }
    
    /// Decreases the zoom level to the previous available zoom factor.
    /// - Throws: `CameraError.zoomOperationFailed` if the zoom operation fails.
    func zoomOut() throws {
        guard !availableZoomFactors.isEmpty else { return }
        
        // Find all zoom factors less than current and get the highest one
        let previousZooms = availableZoomFactors.filter { $0 < currentZoomFactor }
        let previousZoom = previousZooms.max() ?? currentZoomFactor
        
        // If we're already at min zoom, do nothing
        if previousZoom == currentZoomFactor { return }
        
        try setZoomFactor(previousZoom)
    }
    
    /// Returns the current zoom factor.
    var zoomFactor: CGFloat {
        return currentZoomFactor
    }
    
    // Helper method for clamping CGFloat values
    private func clamp(_ value: CGFloat, to range: ClosedRange<CGFloat>) -> CGFloat {
        return max(range.lowerBound, min(value, range.upperBound))
    }
}


// MARK: - A photo capture delegate to process the captured photo.

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {

    private let output: AVCapturePhotoOutput
    private let settings: AVCapturePhotoSettings
    private var continuation: CheckedContinuation<UIImage, Error>?

    init(output: AVCapturePhotoOutput, settings: AVCapturePhotoSettings) {
        self.output = output
        self.settings = settings
    }

    func capturePhoto(with continuation: CheckedContinuation<UIImage, Error>) {
        self.continuation = continuation
        output.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            continuation?.resume(throwing: error)
            return
        }
        guard let cgImage = photo.cgImageRepresentation(),
            let metadataOrientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
                let cgImageOrientation = CGImagePropertyOrientation(rawValue: metadataOrientation) else {
            continuation?.resume(throwing: CameraError.photoCaptureFailed)
            return
        }
        let uiImage = UIImage(cgImage: cgImage, scale: 1, orientation: .from(cgImageOrientation))
        continuation?.resume(returning: uiImage)
    }
}


private extension UIImage.Orientation {

  static func from(_ cgImageOrientation: CGImagePropertyOrientation) -> Self {
    switch cgImageOrientation {
      case .up: .up
      case .upMirrored: .upMirrored
      case .down: .down
      case .downMirrored: .downMirrored
      case .left: .left
      case .leftMirrored: .leftMirrored
      case .right: .right
      case .rightMirrored: .rightMirrored
    }
  }
}

// At the bottom of the file where it already exists
private extension AVCaptureDevice {
    /// Checks if the device has an ultra-wide camera
    var hasUltraWideCamera: Bool {
        return self.deviceType == .builtInUltraWideCamera ||
               (self.position == .back &&
                self.constituentDevices.contains(where: { $0.deviceType == .builtInUltraWideCamera }))
    }
    
    /// Checks if the device has a telephoto camera
    var hasTelephotoCamera: Bool {
        return self.deviceType == .builtInTelephotoCamera ||
               (self.position == .back &&
                self.constituentDevices.contains(where: { $0.deviceType == .builtInTelephotoCamera }))
    }
}
