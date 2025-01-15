//
//  MainDemoView.swift
//
//  Created by Hovik Melikyan on 14.01.25.
//

import SwiftUI

struct MainDemoView: View {

    private let camera = Camera(forSelfie: true)
    @State private var isCameraPresented: Bool = false
    @State private var capturedImage: UIImage?

    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(.gray.opacity(0.25))

                if let capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFit()
                }
                else {
                    Text("CAPTURED IMAGE")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(24)

            Button {
                isCameraPresented = true
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "camera")
                        .font(.system(size: 32))
                    Text("LAUNCH CAMERA")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .padding(.bottom)
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraView(camera: camera, viewfinderShape: .round) { image in
                print("Result:", image?.description ?? "none")
                capturedImage = image
            }
        }
    }
}

#Preview {
    MainDemoView()
}
