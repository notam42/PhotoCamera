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
  
  // Track the device orientation to apply rotations appropriately
  @State private var deviceOrientation: UIDeviceOrientation = .portrait
  
  public init(title: String?, forSelfie: Bool, onConfirm: @escaping (UIImage?) -> Void) {
    self.title = title
    self.camera = Camera(forSelfie: forSelfie)
    self.onConfirm = onConfirm
    // Initialize with the current device orientation
    self._deviceOrientation = State(initialValue: UIDevice.current.orientation.isValidInterfaceOrientation ? UIDevice.current.orientation : .portrait)
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
        
        // Set up device orientation monitoring
        setupOrientationMonitoring()
      }
      .onDisappear {
        // Clean up orientation monitoring on the main thread
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(OrientationObserver.shared)
      }
    }
    .padding(.vertical, title == nil ? 0 : 60)
    .statusBarHidden(true)
    .background(.black)
    .ignoresSafeArea()
    .overlay {
      GeometryReader { proxy in
        orientationAwareTitleOverlay(proxy.size)
        orientationAwareCloseButtonOverlay(proxy.size)
        orientationAwareCameraUIOverlay(proxy.size)
        
        StatusOverlayView(status: camera.status)
          .ignoresSafeArea()
          .rotationEffect(rotationAngle)
          .animation(.easeInOut(duration: 0.3), value: deviceOrientation)
      }
    }
  }
  
  /// Sets up device orientation monitoring
  private func setupOrientationMonitoring() {
    // Start monitoring device orientation changes
    OrientationObserver.shared.startMonitoring { newOrientation in
      self.deviceOrientation = newOrientation
    }
  }
  
  /// Calculates rotation angle based on device orientation
  private var rotationAngle: Angle {
    switch deviceOrientation {
    case .landscapeLeft:
      return .degrees(90)
    case .landscapeRight:
      return .degrees(-90)
    case .portraitUpsideDown:
      return .degrees(180)
    default:
      return .degrees(0)
    }
  }
  
  /// Returns the appropriate edge alignment for the current device orientation
  private var toolbarEdgeAlignment: Alignment {
    switch deviceOrientation {
    case .landscapeLeft:
      return .trailing // Right edge
    case .landscapeRight:
      return .leading // Left edge
    case .portraitUpsideDown:
      return .top // Top edge
    default:
      return .bottom // Bottom edge (portrait)
    }
  }
  
  /// Returns the appropriate edge inset for the current device orientation
  private func toolbarEdgeInset(_ size: CGSize) -> EdgeInsets {
    let padding: CGFloat = 28
    
    switch deviceOrientation {
    case .landscapeLeft:
      return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: padding)
    case .landscapeRight:
      return EdgeInsets(top: 0, leading: padding, bottom: 0, trailing: 0)
    case .portraitUpsideDown:
      return EdgeInsets(top: padding, leading: 0, bottom: 0, trailing: 0)
    default:
      return EdgeInsets(top: 0, leading: 0, bottom: padding, trailing: 0)
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
  
  // MARK: - Orientation aware overlay views
  
  private func orientationAwareTitleOverlay(_ size: CGSize) -> some View {
    Group {
      if let title = title {
        VStack {
          Text(title)
            .font(.title2)
            .foregroundStyle(.white)
            .padding(12)
            .rotationEffect(rotationAngle)
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.easeInOut(duration: 0.3), value: deviceOrientation)
      }
    }
  }
  
  private func orientationAwareCloseButtonOverlay(_ size: CGSize) -> some View {
    ZStack(alignment: .topLeading) {
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 24))
          .foregroundColor(.white)
          .shadow(color: .black.opacity(0.5), radius: 3)
          .frame(width: 44, height: 44)
          .rotationEffect(rotationAngle)
      }
      .padding(8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .animation(.easeInOut(duration: 0.3), value: deviceOrientation)
  }
  
  private func orientationAwareCameraUIOverlay(_ size: CGSize) -> some View {
    ZStack(alignment: toolbarEdgeAlignment) {
      cameraToolbar()
        .rotationEffect(rotationAngle)
        .padding(toolbarEdgeInset(size))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .animation(.easeInOut(duration: 0.3), value: deviceOrientation)
  }
  
  private func updateBlurRadius(_: Bool, _ isSwitching: Bool) {
    withAnimation {
      blurRadius = isSwitching ? 30 : 0
    }
  }
  
  // MARK: - Toolbar
  
  private func cameraToolbar() -> some View {
    HStack {
      if capturedImage != nil {
        retryButton()
        Spacer()
        confirmButton()
      } else {
        photoPickerButton()
        Spacer()
        captureButton()
        Spacer()
        switchCameraButton()
      }
    }
    .foregroundColor(.white)
    .font(.system(size: 24, weight: .medium))
    .frame(height: toolbarHeight)
    .padding(.horizontal, 16)
    .background(.ultraThinMaterial.opacity(0.3))
    .cornerRadius(12)
    .frame(maxWidth: maxToolbarWidth)
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
  
  // MARK: - Internal capture photo method
  
  /// Captures a photo from the camera and applies the shutter blink effect
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

/// A class that safely handles device orientation monitoring
@MainActor
private class OrientationObserver: NSObject {
  static let shared = OrientationObserver()
  private var orientationChanged: ((UIDeviceOrientation) -> Void)?
  
  func startMonitoring(onChange: @escaping (UIDeviceOrientation) -> Void) {
    self.orientationChanged = onChange
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(orientationDidChange),
      name: UIDevice.orientationDidChangeNotification,
      object: nil
    )
    
    if !UIDevice.current.isGeneratingDeviceOrientationNotifications {
      UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
  }
  
  @objc private func orientationDidChange() {
    let orientation = UIDevice.current.orientation
    if orientation.isValidInterfaceOrientation {
      orientationChanged?(orientation)
    }
  }
}
