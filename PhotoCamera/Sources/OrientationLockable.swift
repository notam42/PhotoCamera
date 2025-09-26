//
//  OrientationLockable.swift
//  PhotoCamera
//
//  Created by Manuel Winter on 26.09.25.
//

//import SwiftUI
//import UIKit
//
///// Protocol that must be implemented by the app to enable orientation locking
//public protocol OrientationLockable {
//    /// Locks the orientation to the specified orientation mask
//    static func lockOrientation(_ orientation: UIInterfaceOrientationMask)
//    
//    /// Resets the orientation lock to the default state
//    static func resetOrientation()
//}
//
///// Class that manages orientation locking in a thread-safe manner
//@MainActor
//private final class OrientationLockManager {
//    /// Shared singleton instance
//    static let shared = OrientationLockManager()
//    
//    /// The registered handler that will perform the actual orientation locking
//    private var handler: OrientationLockable.Type?
//    
//    /// Private initializer to enforce singleton pattern
//    private init() {}
//    
//    /// Registers a type as the handler for orientation lock requests
//    func registerHandler(_ handler: OrientationLockable.Type) {
//        self.handler = handler
//    }
//    
//    /// Locks the orientation to the specified orientation mask
//    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
//        handler?.lockOrientation(orientation)
//    }
//    
//    /// Resets the orientation lock to the default state
//    func resetOrientation() {
//        handler?.resetOrientation()
//    }
//}
//
///// View modifier that applies orientation locking to a view
//public struct OrientationLockedModifier: ViewModifier {
//    /// The orientation mask to apply
//    let orientation: UIInterfaceOrientationMask
//    
//    public init(orientation: UIInterfaceOrientationMask) {
//        self.orientation = orientation
//    }
//    
//    public func body(content: Content) -> some View {
//        content
//            .onAppear {
//                Task { @MainActor in
//                    OrientationLockManager.shared.lockOrientation(orientation)
//                }
//            }
//            .onDisappear {
//                Task { @MainActor in
//                    OrientationLockManager.shared.resetOrientation()
//                }
//            }
//    }
//}
//
//// Extension for registering the orientation handler
//public extension OrientationLockable {
//    /// Registers this type as the handler for orientation lock requests
//    static func registerAsOrientationLockHandler() {
//        Task { @MainActor in
//            OrientationLockManager.shared.registerHandler(Self.self)
//        }
//    }
//}
//
//// Extension for View to add orientation locking capability
//public extension View {
//    /// Locks the screen orientation to the specified orientation while this view is presented
//    /// - Parameter orientation: The orientation mask to apply
//    /// - Returns: A modified view that applies the orientation lock
//    func lockOrientation(_ orientation: UIInterfaceOrientationMask) -> some View {
//        modifier(OrientationLockedModifier(orientation: orientation))
//    }
//}

//
//  OrientationLockable.swift
//  PhotoCamera
//
//  Created by Manuel Winter on 26.09.25.
//

//
//  OrientationLockable.swift
//  PhotoCamera
//
//  Created by Manuel Winter on 26.09.25.
//

import SwiftUI
import UIKit

/// Protocol that must be implemented by the app to enable orientation locking
public protocol OrientationLockable {
    /// Locks the orientation to the specified orientation mask
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask)
    
    /// Resets the orientation lock to the default state
    static func resetOrientation()
}

/// Class that manages orientation locking in a thread-safe manner
@MainActor
private final class OrientationLockManager {
    /// Shared singleton instance
    static let shared = OrientationLockManager()
    
    /// The registered handler that will perform the actual orientation locking
    private var handler: OrientationLockable.Type?
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Registers a type as the handler for orientation lock requests
    func registerHandler(_ handler: OrientationLockable.Type) {
        self.handler = handler
    }
    
    /// Locks the orientation to the specified orientation mask
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        handler?.lockOrientation(orientation)
    }
    
    /// Resets the orientation lock to the default state
    func resetOrientation() {
        handler?.resetOrientation()
    }
}

/// A class to monitor device orientation changes
@MainActor
public final class DeviceOrientationManager: ObservableObject {
    /// The shared instance for the orientation manager
    public static let shared = DeviceOrientationManager()

    /// The current orientation of the device
    @Published public private(set) var orientation: UIDeviceOrientation = UIDevice.current.orientation

    /// Private initializer to enforce singleton pattern
    private init() {
        // Start monitoring device orientation
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        // Set up notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )

        // Set initial value
        self.orientation = UIDevice.current.orientation
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        // This needs to be called on the main actor
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    /// Notification handler for orientation changes
    @objc private func orientationChanged() {
        let newOrientation = UIDevice.current.orientation
        // Only update if it's a valid orientation (not face up/down)
        if newOrientation != .faceUp && newOrientation != .faceDown && newOrientation != .unknown {
            self.orientation = newOrientation
        }
    }
}

/// View modifier that applies orientation locking to a view
public struct OrientationLockedModifier: ViewModifier {
    /// The orientation mask to apply
    let orientation: UIInterfaceOrientationMask
    
    public init(orientation: UIInterfaceOrientationMask) {
        self.orientation = orientation
    }
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                Task { @MainActor in
                    OrientationLockManager.shared.lockOrientation(orientation)
                }
            }
            .onDisappear {
                Task { @MainActor in
                    OrientationLockManager.shared.resetOrientation()
                }
            }
    }
}

/// Utility for handling device orientation-based UI adjustments
public enum DeviceOrientationUtility {
    /// Returns the appropriate aspect ratio for camera/images based on the given orientation
    /// - Parameter orientation: The device orientation to consider
    /// - Returns: The aspect ratio as width/height
    public static func getAspectRatio(for orientation: UIDeviceOrientation) -> CGFloat {
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            return 4.0/3.0  // Landscape: 4:3 ratio
        case .portrait, .portraitUpsideDown:
            return 3.0/4.0  // Portrait: 3:4 ratio
        default:
            return 3.0/4.0  // Default to portrait ratio
        }
    }

    /// Determines if the given orientation is in landscape mode
    /// - Parameter orientation: The device orientation to check
    /// - Returns: True if the orientation is landscape, false otherwise
    public static func isLandscape(_ orientation: UIDeviceOrientation) -> Bool {
        orientation == .landscapeLeft || orientation == .landscapeRight
    }

    /// Determines if the given orientation is in portrait mode
    /// - Parameter orientation: The device orientation to check
    /// - Returns: True if the orientation is portrait, false otherwise
    public static func isPortrait(_ orientation: UIDeviceOrientation) -> Bool {
        orientation == .portrait || orientation == .portraitUpsideDown
    }

    /// Returns the appropriate crop ratio for an image based on device orientation
    /// - Parameter orientation: The device orientation to consider
    /// - Returns: The crop ratio to use for the captured image
    public static func getCropRatio(for orientation: UIDeviceOrientation) -> CGFloat {
        getAspectRatio(for: orientation)
    }
}

// Extension for registering the orientation handler
public extension OrientationLockable {
    /// Registers this type as the handler for orientation lock requests
    static func registerAsOrientationLockHandler() {
        Task { @MainActor in
            OrientationLockManager.shared.registerHandler(Self.self)
        }
    }
}

// Extension for View to add orientation locking capability
public extension View {
    /// Locks the screen orientation to the specified orientation while this view is presented
    /// - Parameter orientation: The orientation mask to apply
    /// - Returns: A modified view that applies the orientation lock
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) -> some View {
        modifier(OrientationLockedModifier(orientation: orientation))
    }
    
    /// Adds orientation detection to the view
    /// - Returns: A view that updates when device orientation changes
    func withOrientationDetection() -> some View {
        self.environmentObject(DeviceOrientationManager.shared)
    }
}
