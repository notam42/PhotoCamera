# PhotoCamera module for Swift 6 and iOS 18

PhotoCamera is a slightly simplified and reworked version of Apple's [AVCam demo app](https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app) from WWDC2024. It supports only taking photos, i.e. no video recording, no live photos, and as such can be useful for apps that request the user's selfie, or similar tasks.

Supports iOS and iPadOS, both 18 or higher.

The non-UI modules are separated into a framework which you can link to your project as a package.

The demo app shows how to build a camera view that uses the framework. You can copy the demo app modules to your project and customize them to your needs.

The demo view (`CameraView`) supports several shapes for the viewfinder: round, square, 3x4, and 9x16:

![IMG_0E4B03DB4266-1](https://github.com/user-attachments/assets/10a23bc3-b318-4b5d-a41b-587f306ac71e) ![IMG_FE9A046A87BE-1](https://github.com/user-attachments/assets/a0ac58d5-65e2-45b9-97f3-d85bf10e8538) ![IMG_680C51161968-1](https://github.com/user-attachments/assets/612bd08d-102a-4234-afc1-d12076db9c96) ![IMG_48CB940B0343-1](https://github.com/user-attachments/assets/adac17e5-c1b3-4d22-a4d1-811204fb8761)

Landscape mode is also supported: the view adjusts itself by fitting the buttons on the right and extending the viewfinder to fill the full height of the screen:

![Simulator Screenshot - iPad mini (A17 Pro) - 2025-01-18 at 20 29 33](https://github.com/user-attachments/assets/7a51303c-40e4-4e1e-9a79-301dbbd9c6d3)

The resuling image can be cropped and resizied using the utility methods in `UIImageCameraEx.swift`.

Importing from the photo library is also supported.

## Authors

Hovik Melikyan, https://github.com/crontab
