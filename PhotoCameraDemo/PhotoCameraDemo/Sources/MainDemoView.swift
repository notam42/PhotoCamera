//
//  MainDemoView.swift
//
//  Created by Hovik Melikyan on 15.01.25.
//

import SwiftUI
import AVFoundation

struct MainDemoView: View {

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
            CameraView(title: "Take a selfie", forSelfie: true, isRound: true) { image in
                capturedImage = image?.fitted(maxWidth: 500)
            }
        }
    }
}

#Preview {
    MainDemoView()
}
