/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays controls to capture, switch cameras, and view the last captured media item.
*/

import SwiftUI
import PhotosUI

/// A view that displays controls to capture, switch cameras, and view the last captured media item.
struct MainToolbar: PlatformView {

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let camera: Camera

    var body: some View {
        HStack {
			PhotoPickerButton()
            Spacer()
            CaptureButton(camera: camera)
            Spacer()
            SwitchCameraButton(camera: camera)
        }
        .foregroundColor(.white)
        .font(.system(size: 24))
        .frame(width: width, height: height)
        .padding([.leading, .trailing])
    }
    
    var width: CGFloat? { isRegularSize ? 250 : nil }
    var height: CGFloat? { 80 }
}

private struct PhotoPickerButton: View {

    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        PhotosPicker( selection: $selectedItems, matching: .images, photoLibrary: .shared()) {
            Image(systemName: "photo.on.rectangle")
        }
        .frame(width: 64.0, height: 64.0)
        .cornerRadius(8)
    }
}


#Preview {
    Group {
        MainToolbar(camera: Camera())
    }
}
