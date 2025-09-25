//
//  DeviceLookup.swift
//
//  Created by Hovik Melikyan on 15.01.25.
//

import AVFoundation

/// An object that retrieves camera devices.
final class DeviceLookup {
  
  // Discovery sessions to find the front and back cameras, and external cameras in iPadOS.
  private let frontCameraDiscoverySession: AVCaptureDevice.DiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: .front)
  private let backCameraDiscoverySession: AVCaptureDevice.DiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInWideAngleCamera], mediaType: .video, position: .back)
  private let externalCameraDiscoverSession: AVCaptureDevice.DiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified)
  
  /// Returns the system-preferred camera for the host system.
  func defaultCamera(forSelfie: Bool) throws -> AVCaptureDevice {
    guard let result = forSelfie ? frontCameraDiscoverySession.devices.first : (backCameraDiscoverySession.devices.first ?? externalCameraDiscoverSession.devices.first) else {
      throw CameraError.videoDeviceUnavailable
    }
    return result
  }
  
  var cameras: [AVCaptureDevice] {
    // Populate the cameras array with the available cameras.
    var cameras: [AVCaptureDevice] = []
    if let backCamera = backCameraDiscoverySession.devices.first {
      cameras.append(backCamera)
    }
    if let frontCamera = frontCameraDiscoverySession.devices.first {
      cameras.append(frontCamera)
    }
    // iPadOS supports connecting external cameras.
    if let externalCamera = externalCameraDiscoverSession.devices.first {
      cameras.append(externalCamera)
    }
    
#if !targetEnvironment(simulator)
    if cameras.isEmpty {
      fatalError("No camera devices are found on this system.")
    }
#endif
    return cameras
  }
}
