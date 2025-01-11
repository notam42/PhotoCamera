/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents controls to enable capture features.
*/

import SwiftUI

/// A view that presents controls to enable capture features.
struct FeaturesToolbar<CameraModel: Camera>: PlatformView {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: CameraModel
    
    var body: some View {
        HStack(spacing: 30) {
            Spacer()
            prioritizePicker
        }
        .buttonStyle(DefaultButtonStyle(size: isRegularSize ? .large : .small))
        .padding([.leading, .trailing])
        // Hide the toolbar items when a person interacts with capture controls.
        .opacity(camera.prefersMinimizedUI ? 0 : 1)
    }

    @ViewBuilder
    var prioritizePicker: some View {
        Menu {
            Picker("Quality Prioritization", selection: $camera.qualityPrioritization) {
                ForEach(QualityPrioritization.allCases) {
                    Text($0.description)
                        .font(.body.weight(.bold))
                }
            }

        } label: {
            switch camera.qualityPrioritization {
            case .speed:
                Image(systemName: "dial.low")
            case .balanced:
                Image(systemName: "dial.medium")
            case .quality:
                Image(systemName: "dial.high")
            }
        }
    }
    
    @ViewBuilder
    var compactSpacer: some View {
        if !isRegularSize {
            Spacer()
        }
    }
}
