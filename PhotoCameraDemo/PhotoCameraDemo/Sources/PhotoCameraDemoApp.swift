//
//  PhotoCameraDemoApp.swift
//
//  Created by Hovik Melikyan on 15.01.25.
//

import SwiftUI

@main
struct PhotoCameraDemoApp: App {

    // An indication of the scene's operational state.
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            MainDemoView()
        }
    }
}
