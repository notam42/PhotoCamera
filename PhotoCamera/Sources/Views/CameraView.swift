//
//  CameraView.swift
//  PhotoCamera
//
//  Created by Manuel Winter on 20.09.25.
//


import SwiftUI
import AVKit
import UIKit.UIImage
import PhotosUI

private let largeButtonSize = CGSize(width: 64, height: 64)
private let toolbarHeight = 88.0
private let maxToolbarWidth = 360.0
private let captureButtonDimension = 68.0


/*
 struct MainDemoView: View {
 @Environment(\.verticalSizeClass) private var verticalSizeClass
 @Environment(\.horizontalSizeClass) private var horizontalSizeClass
 
 @State private var isCameraPresented: Bool = false
 @State private var capturedImage: UIImage?
 
 var body: some View {
 if verticalSizeClass == .regular && horizontalSizeClass == .regular {
 main()
 .sheet(isPresented: $isCameraPresented, content: cameraView)
 }
 else {
 main()
 .fullScreenCover(isPresented: $isCameraPresented, content: cameraView)
 }
 }
 
 
 private func main() -> some View {
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
 }
 
 
 private func cameraView() -> some View {
 CameraView(title: "Take a selfie", forSelfie: true) { image in
 capturedImage = image?.fitted(maxWidth: 500)
 }
 }
 }
 
 #Preview {
 MainDemoView()
 }
 */
public struct CameraView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  
  private let title: String?
  private let onConfirm: (UIImage?) -> Void
  
  @State private var camera: Camera
  @State private var blink: Bool = false // capture blink effect
  @State private var blurRadius = CGFloat.zero // camera switch blur effect
  @State private var capturedImage: UIImage? // result
  @State private var libraryItem: PhotosPickerItem?
  
  //    @State private var isZooming = false
  //    @State private var zoomDisplayTimer: Timer?
  //    @State private var zoomStartFactor: CGFloat = 1.0
  //    @GestureState private var magnificationState: CGFloat = 1.0
  
  public init(title: String?, forSelfie: Bool, onConfirm: @escaping (UIImage?) -> Void) {
    self.title = title
    self.camera = Camera(forSelfie: forSelfie)
    self.onConfirm = onConfirm
  }
  
  public var body: some View {
    GeometryReader { proxy in
      // A container view that manages the placement of the preview.
      let isPortrait = verticalSizeClass == .regular && horizontalSizeClass == .compact
      
      viewfinderContainer(viewSize: proxy.size, isPortrait: isPortrait) {
        ViewfinderView(camera: camera)
        // Handle capture events from device hardware buttons.
          .onCameraCaptureEvent { event in
            if event.phase == .ended {
              capturePhoto()
            }
          }
        
        // Focus and expose at the tapped point.
          .onTapGesture { location in
            Task { await camera.focusAndExpose(at: location) }
          }
          .opacity(blink ? 0 : 1)
        
        // A view that provides a preview of the captured content.
          .overlay {
            // This is done as an overlay because hiding and showing the video layer (ViewfinderView above) without restarting the session causes strange problems on macOS, though is fine on the iPhone.
            if let capturedImage {
              Image(uiImage: capturedImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
            }
          }
      }
      .frame(maxWidth: .infinity)
      
      .task {
        await camera.start()
      }
    }
    .padding(.vertical, title == nil ? 0 : 60) // make room for the title if present
    
    .statusBarHidden(true)
    .background(.black)
    .ignoresSafeArea() // order is important
    .overlay {
      closeButton()
      if let title {
        VStack {
          Text(title)
            .font(.title2)
            .foregroundStyle(.white)
            .padding(12)
          Spacer()
        }
      }
      cameraUI()
    }
  }
  
  private func closeButton() -> some View {
    VStack(alignment: .trailing) {
      HStack {
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark")
        }
        .frame(width: 44, height: 44)
        .foregroundColor(.white)
        .font(.system(size: 24))
        .shadow(color: .black.opacity(0.5), radius: 3)
        .padding(8)
        Spacer()
      }
      Spacer()
    }
  }
  
  // MARK: - Internal capture photo method
  
  private func capturePhoto() {
    Task {
      // "Blink" the viewfinder as if it's the shutter
      withAnimation(.linear(duration: 0.05)) {
        blink = true
      } completion: {
        withAnimation(.linear(duration: 0.05)) {
          blink = false
        }
      }
      
      // Do capture
      capturedImage = try? await camera.capturePhoto()
    }
  }
  
  // MARK: - viewfinder container
  
  /// Creates the viewfinder container with appropriate aspect ratio based on device orientation
  /// - Parameters:
  ///   - viewSize: The available view size
  ///   - isPortrait: Whether the device is in portrait orientation
  ///   - content: The content to display within the viewfinder
  private func viewfinderContainer(viewSize: CGSize, isPortrait: Bool, @ViewBuilder content: @escaping () -> some View) -> some View {
    VStack {
      // Use 3:4 for portrait, 4:3 for landscape
      let aspectRatio: CGFloat = isPortrait ? 3.0/4.0 : 4.0/3.0
      
      // Calculate dimensions to fit the available space while maintaining the right aspect ratio
      let availableWidth = min(viewSize.width, viewSize.height * aspectRatio) - 32
      let width = max(0, availableWidth)
      let height = width / aspectRatio
      
      Spacer()
      content()
        .aspectRatio(aspectRatio, contentMode: .fill)
        .frame(width: width, height: height)
        .blur(radius: blurRadius, opaque: true)
        .clipped()
        .onChange(of: camera.isSwitchingVideoDevices, updateBlurRadius(_:_:))
      Spacer()
    }
  }
  
  private func updateBlurRadius(_: Bool, _ isSwitching: Bool) {
    withAnimation {
      blurRadius = isSwitching ? 30 : 0
    }
  }
  
  /*
   // MARK: - Zoom
   /// Displays available optical zoom levels as a horizontal picker
   private func opticalZoomPicker() -> some View {
   HStack(spacing: 24) {
   ForEach(camera.opticalZoomFactors, id: \.self) { factor in
   Button {
   Task {
   await camera.smoothZoom(to: factor)
   }
   } label: {
   Text("\(Int(factor))×")
   .foregroundStyle(abs(camera.zoomFactor - factor) < 0.1 ? .yellow : .white)
   .font(.system(size: 16, weight: .semibold))
   .padding(.vertical, 8)
   .padding(.horizontal, 12)
   .background(
   Capsule()
   .fill(Color.black.opacity(0.5))
   )
   }
   }
   }
   .padding(8)
   .background(
   Capsule()
   .fill(Color.black.opacity(0.3))
   )
   }
   
   /// Displays the current zoom level during zooming
   private func zoomLevelDisplay() -> some View {
   Text(String(format: "%.1f×", camera.zoomFactor))
   .font(.system(size: 20, weight: .bold))
   .foregroundStyle(.white)
   .padding(10)
   .background(
   RoundedRectangle(cornerRadius: 10)
   .fill(Color.black.opacity(0.6))
   )
   .opacity(isZooming ? 1.0 : 0.0)
   .animation(.easeOut(duration: 0.2), value: isZooming)
   }
   
   /// Sets up the magnification gesture for zooming
   private func setupMagnificationGesture() -> some Gesture {
   MagnificationGesture()
   .onChanged { value in
   // Cancel any existing hide timer when user is actively zooming
   zoomDisplayTimer?.invalidate()
   isZooming = true
   }
   .updating($magnificationState) { value, state, _ in
   state = value
   }
   .onEnded { value in
   // Calculate the target zoom factor based on the pinch gesture
   let targetZoom = zoomStartFactor * value
   
   // Schedule zoom display to disappear
   zoomDisplayTimer?.invalidate()
   zoomDisplayTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
   withAnimation {
   isZooming = false
   }
   }
   
   // Apply the zoom change
   Task {
   await camera.smoothZoom(to: targetZoom)
   // Update the start zoom factor for the next gesture
   zoomStartFactor = camera.zoomFactor
   }
   }
   }
   */
  
  // MARK: - camera UI
  private func cameraUI() -> some View {
    GeometryReader { proxy in
      let landscape = proxy.size.width > proxy.size.height
      stack(vertical: !landscape) {
        Spacer()
        stack(vertical: landscape) {
          Spacer()
          cameraToolbar(vertical: landscape)
          Spacer()
        }
        .padding(landscape ? .trailing : .bottom, 28)
      }
      .overlay {
        StatusOverlayView(status: camera.status)
          .ignoresSafeArea()
      }
    }
  }
  
  /*
   // Update your cameraUI method to include the zoom picker and display
   private func cameraUI() -> some View {
   GeometryReader { proxy in
   let landscape = proxy.size.width > proxy.size.height
   stack(vertical: !landscape) {
   Spacer()
   
   // Add the optical zoom picker at the bottom
   VStack {
   Spacer()
   
   // Show zoom level indicator in the center during zooming
   zoomLevelDisplay()
   .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
   
   if capturedImage == nil {
   opticalZoomPicker()
   .padding(.bottom, 16)
   }
   
   stack(vertical: landscape) {
   Spacer()
   cameraToolbar(vertical: landscape)
   Spacer()
   }
   .padding(landscape ? .trailing : .bottom, 28)
   }
   }
   .overlay {
   StatusOverlayView(status: camera.status)
   .ignoresSafeArea()
   }
   }
   // Update zoom start factor whenever the camera's zoom factor changes
   .onChange(of: camera.zoomFactor) { newValue in
   zoomStartFactor = newValue
   }
   */
  
  // MARK: - Toolbar
  
  private func cameraToolbar(vertical: Bool) -> some View {
    stack(vertical: vertical) {
      if capturedImage != nil {
        retryButton()
        Spacer()
        confirmButton()
      }
      else {
        photoPickerButton()
        Spacer()
        captureButton()
        Spacer()
        switchCameraButton()
      }
    }
    .foregroundColor(.white)
    .font(.system(size: 24, weight: .medium))
    .frame(width: vertical ? toolbarHeight : nil, height: vertical ? nil : toolbarHeight)
    .padding(vertical ? .vertical : .horizontal, 16)
    .background(.ultraThinMaterial.opacity(0.3))
    .cornerRadius(12)
    .frame(maxWidth: vertical ? nil : maxToolbarWidth, maxHeight: vertical ? maxToolbarWidth : nil)
  }
  
  // MARK: - Confirm buttons
  
  private func confirmButton() -> some View {
    Button {
      dismiss()
      // Use the appropriate aspect ratio based on orientation when cropping
      let isPortrait = verticalSizeClass == .regular && horizontalSizeClass == .compact
      let aspectRatio = isPortrait ? 3.0/4.0 : 4.0/3.0
      onConfirm(capturedImage?.cropped(ratio: aspectRatio))
    } label: {
      Image(systemName: "checkmark")
    }
    .frame(width: largeButtonSize.width, height: largeButtonSize.height)
  }
  
  private func retryButton() -> some View {
    Button {
      capturedImage = nil
    } label: {
      Image(systemName: "arrow.uturn.left")
    }
    .frame(width: largeButtonSize.width, height: largeButtonSize.height)
  }
  
  // MARK: - Photo picker button
  
  private func photoPickerButton() -> some View {
    PhotosPicker(selection: $libraryItem, matching: .images, photoLibrary: .shared()) {
      Image(systemName: "photo.on.rectangle")
    }
    .frame(width: largeButtonSize.width, height: largeButtonSize.height)
    .onChange(of: libraryItem) {
      if let libraryItem {
        Task {
          if let data = try? await libraryItem.loadTransferable(type: Data.self) {
            capturedImage = UIImage(data: data)
          }
        }
      }
      libraryItem = nil
    }
  }
  
  // MARK: - Switch camera button
  
  private func switchCameraButton() -> some View {
    Button {
      Task {
        await camera.switchVideoDevices()
      }
    } label: {
      Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.camera")
    }
    .frame(width: largeButtonSize.width, height: largeButtonSize.height)
    .disabled(camera.isSwitchingVideoDevices)
  }
  
  // MARK: - Capture button
  
  private func captureButton() -> some View {
    ZStack {
      let lineWidth = 4.0
      Circle()
        .stroke(lineWidth: lineWidth)
        .fill(.white)
      Button {
        capturePhoto()
      } label: {
        Circle()
          .inset(by: lineWidth * 1.2)
          .fill(.white)
      }
      .buttonStyle(PhotoButtonStyle())
    }
    .frame(width: captureButtonDimension)
  }
  
  private struct PhotoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
  }
}

// MARK: - View.stack() extension

private extension View {
  @ViewBuilder
  func stack<Content: View>(vertical: Bool, @ViewBuilder content: () -> Content) -> some View {
    if vertical {
      VStack(spacing: 0, content: content)
    }
    else {
      HStack(spacing: 0, content: content)
    }
  }
}


// MARK: - Previews

#Preview("Round") {
  CameraView(title: "Take a selfie", forSelfie: true) { _ in }
}

#Preview("Square") {
  CameraView(title: "Take a selfie", forSelfie: true) { _ in }
}
