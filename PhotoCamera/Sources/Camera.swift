//
//  Camera.swift
//
//  Created by Hovik Melikyan on 15.01.25.
//
// Hi

@preconcurrency import AVFoundation
import UIKit.UIImage

public enum CameraStatus {
    case unknown
    case unauthorized
    case failed
    case running
}

/*
/// An object that provides the interface to the features of the camera.
///
@Observable
@MainActor
public final class Camera {

    /// The app's capture session.
    public var captureSession: AVCaptureSession { captureService.captureSession }

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
    
  // MARK: - Zoom Controls

  /// Sets the zoom factor to the specified value, constrained by device limits.
  /// - Parameter factor: The desired zoom factor.
  public func setZoomFactor(_ factor: CGFloat) async {
      guard !Self.isPreview else { return }
      
    let constrainedFactor = max(minZoomFactor, min(maxZoomFactor, factor))
      guard constrainedFactor != zoomFactor else { return }
      
      do {
          try await captureService.setZoomFactor(constrainedFactor)
          zoomFactor = constrainedFactor
      } catch {
          print("Failed to set zoom factor: \(error)")
      }
  }

  /// Toggles between available optical zoom levels in a sequential manner.
  /// This is useful for UI controls that cycle through optical zoom levels.
  /// - Returns: The new zoom factor that was selected.
  @discardableResult
  public func toggleOpticalZoom() async -> CGFloat {
      guard !Self.isPreview, !availableZoomFactors.isEmpty else { return zoomFactor }

      // Find the index of the closest current zoom factor
      let currentIndex = availableZoomFactors.firstIndex { abs($0 - zoomFactor) < 0.1 }
          ?? availableZoomFactors.lastIndex { $0 < zoomFactor }
          ?? 0

      // Get the next index, wrapping around if needed
      let nextIndex = (currentIndex + 1) % availableZoomFactors.count
      let nextZoomFactor = availableZoomFactors[nextIndex]

      // Apply the new zoom factor with a smooth transition
      await smoothZoom(to: nextZoomFactor)
      return nextZoomFactor
  }

  /// Sets the zoom factor to a specific optical zoom level if it exists in availableZoomFactors.
  /// - Parameter opticalZoomLevel: The specific optical zoom level to set.
  /// - Returns: `true` if the zoom was applied, `false` if the zoom level was not available.
  @discardableResult
  public func setOpticalZoomLevel(_ opticalZoomLevel: CGFloat) async -> Bool {
      guard !Self.isPreview, availableZoomFactors.contains(opticalZoomLevel) else { return false }
      await smoothZoom(to: opticalZoomLevel)
      return true
  }

  /// Represents the state of a magnification gesture.
  public enum MagnificationGestureState {
      case began
      case changed
      case ended
  }

  /// Handles a magnification gesture for zoom control.
  /// - Parameters:
  ///   - state: The current state of the magnification gesture.
  ///   - scale: The current magnification scale value.
  ///   - initialZoom: The zoom factor when the gesture began (used for relative calculations).
  /// - Returns: The current zoom factor after applying the gesture.
  @discardableResult
  public func handleMagnificationGesture(state: MagnificationGestureState, scale: CGFloat, initialZoom: CGFloat) async -> CGFloat {
      guard !Self.isPreview else { return zoomFactor }
      
      switch state {
      case .began:
          // No action needed on begin, just return current zoom
          return zoomFactor
          
      case .changed:
          // Calculate and apply the new zoom factor based on the gesture
          let newZoomFactor = max(minZoomFactor, min(maxZoomFactor, initialZoom * scale))
          await setZoomFactor(newZoomFactor)
          return zoomFactor
          
      case .ended:
          // When the gesture ends, snap to the nearest optical zoom level if close enough
          let nearestOptical = nearestSupportedZoomFactor(to: zoomFactor)
          if abs(nearestOptical - zoomFactor) < 0.2 { // Threshold for snapping
              await smoothZoom(to: nearestOptical, duration: 0.2)
          }
          return zoomFactor
      }
  }
  
  /// Represents the state of a zoom gesture.
  public enum GestureState {
      case began
      case changed(initialZoom: CGFloat)
      case ended
  }
  
    // MARK: - Photo capture
    
    /// Captures a photo
    public func capturePhoto() async throws -> UIImage {
        guard !Self.isPreview else { return UIImage() }
        return try await captureService.capturePhoto()
    }

    /// Performs a focus and expose operation at the specified screen point.
    public func focusAndExpose(at point: CGPoint) async {
        guard !Self.isPreview else { return }
        await captureService.focusAndExpose(at: point)
    }

    public static let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

*/

@Observable
@MainActor
public final class Camera {

    /// The app's capture session.
    public var captureSession: AVCaptureSession { captureService.captureSession }

    /// The current status of the camera, such as unauthorized, running, or failed.
    public private(set) var status = CameraStatus.unknown

    /// A Boolean value that indicates whether the app is currently switching video devices.
    public private(set) var isSwitchingVideoDevices = false

    /// The current zoom factor of the camera
    public private(set) var zoomFactor: CGFloat = 1.0

    /// The minimum zoom factor supported by the current device
    public private(set) var minZoomFactor: CGFloat = 1.0
    
    /// The maximum zoom factor supported by the current device
    public private(set) var maxZoomFactor: CGFloat = 10.0

    /// Available optical zoom factors for the current device
    public private(set) var availableZoomFactors: [CGFloat] = []

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
            
            // Initialize zoom settings after camera starts
            await fetchAvailableZoomFactors()
        } catch {
            print("Failed to start capture service. \(error)")
            status = .failed
        }
    }
    
    /// Fetches the available zoom factors from the CaptureService
    public func fetchAvailableZoomFactors() async {
        guard !Self.isPreview else { return }
        
        availableZoomFactors = await captureService.zoomFactors
        zoomFactor = await captureService.zoomFactor
        
        // Default minimum zoom is always 1.0
      minZoomFactor = availableZoomFactors.min() ?? 1.0
        
        // Maximum zoom should come from CaptureService's value (10.0)
      maxZoomFactor = 10.0
    }
    
    // MARK: - Changing devices

    /// Selects the next available video device for capture.
    public func switchVideoDevices() async {
        guard !Self.isPreview else { return }
        isSwitchingVideoDevices = true
        defer { isSwitchingVideoDevices = false }
        await captureService.selectNextVideoDevice()
        
        // Update zoom capabilities after device switch
        await fetchAvailableZoomFactors()
    }
    
    // MARK: - Zoom Controls

    /// Sets the zoom factor to the specified value, constrained by device limits.
    /// - Parameter factor: The desired zoom factor.
    public func setZoomFactor(_ factor: CGFloat) async {
        guard !Self.isPreview else { return }
        
        let constrainedFactor = max(minZoomFactor, min(maxZoomFactor, factor))
        guard constrainedFactor != zoomFactor else { return }
        
        do {
            try await captureService.setZoomFactor(constrainedFactor)
            zoomFactor = constrainedFactor
        } catch {
            print("Failed to set zoom factor: \(error)")
        }
    }
    
    /// Smoothly transitions to the target zoom factor over the specified duration
    /// - Parameters:
    ///   - target: The target zoom factor
    ///   - duration: The duration of the transition in seconds
  public func smoothZoom(to target: CGFloat, duration: TimeInterval = 0.3) async {
      guard !Self.isPreview else { return }

      let constrainedTarget = max(minZoomFactor, min(maxZoomFactor, target))
      guard constrainedTarget != zoomFactor else { return }

      // Calculate how many steps to take for smooth animation
      let steps = 20
      let delay = duration / TimeInterval(steps)
      let zoomDifference = constrainedTarget - zoomFactor
      let zoomStepSize = zoomDifference / CGFloat(steps)
      
      // Perform the zoom in small increments for a smooth effect
      for step in 1...steps {
          let intermediateZoom = zoomFactor + (zoomStepSize * CGFloat(step))
          await setZoomFactor(intermediateZoom)
          
          // Short delay between zoom adjustments for smoothness
          try? await Task.sleep(for: .seconds(delay))
          
          // Check for cancellation between steps
          if Task.isCancelled {
              break
          }
      }
      
      // Ensure we end exactly at the target zoom factor
      await setZoomFactor(constrainedTarget)
  }
    
    /// Finds the nearest supported optical zoom factor to the given value
    /// - Parameter value: The zoom factor to find the nearest supported value for
    /// - Returns: The nearest supported zoom factor
    public func nearestSupportedZoomFactor(to value: CGFloat) -> CGFloat {
        guard !availableZoomFactors.isEmpty else { return value }
        
        return availableZoomFactors.min(by: { abs($0 - value) < abs($1 - value) }) ?? value
    }

    /// Toggles between available optical zoom levels in a sequential manner.
    /// This is useful for UI controls that cycle through optical zoom levels.
    /// - Returns: The new zoom factor that was selected.
    @discardableResult
    public func toggleOpticalZoom() async -> CGFloat {
        guard !Self.isPreview, !availableZoomFactors.isEmpty else { return zoomFactor }

        // Find the index of the closest current zoom factor
        var currentIndex = 0
        if let index = availableZoomFactors.firstIndex(where: { abs($0 - zoomFactor) < 0.1 }) {
            currentIndex = index
        } else if let index = availableZoomFactors.lastIndex(where: { $0 < zoomFactor }) {
            currentIndex = index
        }

        // Get the next index, wrapping around if needed
        let nextIndex = (currentIndex + 1) % availableZoomFactors.count
        let nextZoomFactor = availableZoomFactors[nextIndex]

        // Apply the new zoom factor with a smooth transition
        await smoothZoom(to: nextZoomFactor)
        return nextZoomFactor
    }

    /// Sets the zoom factor to a specific optical zoom level if it exists in availableZoomFactors.
    /// - Parameter opticalZoomLevel: The specific optical zoom level to set.
    /// - Returns: `true` if the zoom was applied, `false` if the zoom level was not available.
    @discardableResult
    public func setOpticalZoomLevel(_ opticalZoomLevel: CGFloat) async -> Bool {
        guard !Self.isPreview, availableZoomFactors.contains(opticalZoomLevel) else { return false }
        await smoothZoom(to: opticalZoomLevel)
        return true
    }

    /// Represents the state of a magnification gesture.
    public enum MagnificationGestureState {
        case began
        case changed
        case ended
    }

    /// Handles a magnification gesture for zoom control.
    /// - Parameters:
    ///   - state: The current state of the magnification gesture.
    ///   - scale: The current magnification scale value.
    ///   - initialZoom: The zoom factor when the gesture began (used for relative calculations).
    /// - Returns: The current zoom factor after applying the gesture.
    @discardableResult
    public func handleMagnificationGesture(state: MagnificationGestureState, scale: CGFloat, initialZoom: CGFloat) async -> CGFloat {
        guard !Self.isPreview else { return zoomFactor }
        
        switch state {
        case .began:
            // No action needed on begin, just return current zoom
            return zoomFactor
            
        case .changed:
            // Calculate and apply the new zoom factor based on the gesture
            let newZoomFactor = max(minZoomFactor, min(maxZoomFactor, initialZoom * scale))
            await setZoomFactor(newZoomFactor)
            return zoomFactor
            
        case .ended:
            // When the gesture ends, snap to the nearest optical zoom level if close enough
            let nearestOptical = nearestSupportedZoomFactor(to: zoomFactor)
            if abs(nearestOptical - zoomFactor) < 0.2 { // Threshold for snapping
                await smoothZoom(to: nearestOptical, duration: 0.2)
            }
            return zoomFactor
        }
    }
    
    /// Represents the state of a zoom gesture with simplified state management.
    public enum GestureState {
        case began
        case changed(initialZoom: CGFloat)
        case ended
    }
    
    /// Handles a zoom gesture with simplified state management
    /// - Parameters:
    ///   - state: The current state of the gesture
    ///   - value: The magnification value
    /// - Returns: The initial zoom factor when gesture begins, otherwise current zoom
    @discardableResult
    public func handleZoomGesture(state: GestureState, value: CGFloat) async -> CGFloat {
        guard !Self.isPreview else { return 1.0 }

        switch state {
        case .began:
            return zoomFactor

        case .changed(let initialZoom):
            let newZoomFactor = max(minZoomFactor, min(maxZoomFactor, initialZoom * value))
            await setZoomFactor(newZoomFactor)
            return initialZoom

        case .ended:
            let nearestOptical = nearestSupportedZoomFactor(to: zoomFactor)
            if abs(nearestOptical - zoomFactor) < 0.2 {
                await smoothZoom(to: nearestOptical, duration: 0.2)
            }
            return zoomFactor
        }
    }
    
    // MARK: - Photo capture
    
    /// Captures a photo
    public func capturePhoto() async throws -> UIImage {
        guard !Self.isPreview else { return UIImage() }
        return try await captureService.capturePhoto()
    }

    /// Performs a focus and expose operation at the specified screen point.
    public func focusAndExpose(at point: CGPoint) async {
        guard !Self.isPreview else { return }
        await captureService.focusAndExpose(at: point)
    }

    public static let isPreview: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}
