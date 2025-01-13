/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A sample app that shows how to a use the AVFoundation capture APIs to perform media capture.
*/

import os
import SwiftUI

@main
/// The AVCam app's main entry point.
struct AVCamApp: App {

    private let camera = Camera(forSelfie: true)
    
    // An indication of the scene's operational state.
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            CameraView(camera: camera, viewfinderShape: .round)
                .statusBarHidden(true)
        }
    }
}

/// A global logger for the app.
let logger = Logger()
