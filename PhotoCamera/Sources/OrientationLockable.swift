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
}
