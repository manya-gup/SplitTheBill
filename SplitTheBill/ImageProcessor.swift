import UIKit
import CoreImage

class ImageProcessor {
    static func correctImageOrientation(image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        switch image.imageOrientation {
        case .right:
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
        case .down:
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
        case .left:
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
        default:
            return image
        }
    }

    static func preprocessImageGrayscaleThreshold(image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(0.0, forKey: kCIInputSaturationKey)

        let thresholdFilter = CIFilter(name: "CIColorClamp")
        thresholdFilter?.setValue(filter?.outputImage, forKey: kCIInputImageKey)
        thresholdFilter?.setValue(CIVector(x: 0.7, y: 0.7, z: 0.7, w: 1.0), forKey: "inputMaxComponents")
        thresholdFilter?.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0), forKey: "inputMinComponents")

        let context = CIContext(options: nil)
        if let output = thresholdFilter?.outputImage, let cgImageResult = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImageResult)
        }
        return nil
    }

    static func preprocessImageSharpen(image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CISharpenLuminance")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(2.0, forKey: kCIInputSharpnessKey)

        let context = CIContext(options: nil)
        if let output = filter?.outputImage, let cgImageResult = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImageResult)
        }
        return nil
    }

    static func preprocessImageBrighten(image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.5, forKey: kCIInputBrightnessKey)

        let context = CIContext(options: nil)
        if let output = filter?.outputImage, let cgImageResult = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImageResult)
        }
        return nil
    }
}
