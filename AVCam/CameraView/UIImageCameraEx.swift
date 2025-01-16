//
//  UIImageCameraEx.swift
//
//  Created by Hovik Melikyan on 15.01.25.
//

import UIKit.UIImage

extension UIImage {

    func fitted(maxWidth: CGFloat) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = maxWidth / size.width
        guard scale >= 1 else {
            return self
        }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // important; otherwise becomes x3 because it thinks it's for retina display
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func cropped(ratio: CGFloat) -> UIImage {
        // Start with an optimistic assumption that only the height should be changed
        var newWidth = size.width
        var newHeight: CGFloat = newWidth / ratio

        // Now see if the new height is greater than the original one and if so, recalculate both width and height:
        if newHeight > size.height {
            newWidth = size.height * ratio
            newHeight = size.height
        }

        // Crop:
        newWidth = floor(newWidth)
        newHeight = floor(newHeight)
        return cropped(CGRect(x: max(0, (size.width - newWidth) / 2), y: max(0, (size.height - newHeight) / 2), width: newWidth, height: newHeight))
    }

    func cropped(_ cropFrame: CGRect) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: cropFrame.size, format: format).image { _ in
            draw(at: CGPoint(x: -cropFrame.origin.x, y: -cropFrame.origin.y))
        }
    }

    func toJpeg() -> Data? {
        jpegData(compressionQuality: 0.8)
    }
}
