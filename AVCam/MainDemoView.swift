//
//  MainDemoView.swift
//
//  Created by Hovik Melikyan on 14.01.25.
//

import SwiftUI

struct MainDemoView: View {

    private let camera = Camera(forSelfie: true)
    @State private var isCameraPresented: Bool = false

    var body: some View {
        VStack {
            Button("Launch Camera") {
                isCameraPresented = true
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraView(camera: camera, viewfinderShape: .round) { image in
                print("Result:", image?.description ?? "none")
            }
        }
    }
}

#Preview {
    MainDemoView()
}
