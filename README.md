# PhotoCamera module for Swift 6 and iOS 18

PhotoCamera is a slightly simplified and reworked version of Apple's [AVCam demo app](https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app) from WWDC2024. It supports only taking photos, i.e. no video recording, no live photos, and as such can be useful for apps that request the user's selfie, or similar tasks.

Supports iOS and iPadOS, both 18 or higher.

The non-UI modules are separated into a framework which you can link to your project as a package.

The demo app shows how to build a camera view that uses the framework. You can copy the demo app modules to your project and customize them to your needs.

The demo view (`CameraView`) supports two shapes for the viewfinder, round and square:

![IMG_0E4B03DB4266-1](https://github.com/user-attachments/assets/10a23bc3-b318-4b5d-a41b-587f306ac71e) ![IMG_FE9A046A87BE-1](https://github.com/user-attachments/assets/a0ac58d5-65e2-45b9-97f3-d85bf10e8538)

Importing from the photo library is also supported.

The resuling image can be cropped and resizied programmatically using the utility methods in the demo app's `UIImageCameraEx.swift`.

## Authors

[Hovik Melikyan](https://github.com/crontab)
