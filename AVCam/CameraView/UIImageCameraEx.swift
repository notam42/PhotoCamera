//
//  UIImageCameraEx.swift
//
//  Created by Hovik Melikyan on 15.01.25.
//

import UIKit.UIImage

extension UIImage {

    func toJpeg(maxNewWidth: CGFloat) -> Data? {
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = maxNewWidth / size.width
        if scale < 1 {
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1 // important; otherwise becomes x3 because it thinks it's for retina display
            return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
                draw(in: CGRect(origin: .zero, size: newSize))
            }
            .toJpeg()
        }
        else {
            return toJpeg()
        }
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
