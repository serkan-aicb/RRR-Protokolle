import Foundation
import UIKit

extension Date {
    var germanDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    var germanDateTimeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

extension UIImage {
    /// Komprimiert das Bild iterativ, bis es die Zielgröße unterschreitet oder
    /// die minimale Qualität erreicht ist. Wird genutzt, damit die gesamte
    /// E-Mail inklusive PDF und Bildern möglichst unter 20 MB bleibt.
    func compressedJPEGData(maxBytes: Int, minQuality: CGFloat = 0.3) -> Data {
        var quality: CGFloat = 0.8
        var data = jpegData(compressionQuality: quality) ?? Data()

        while data.count > maxBytes && quality > minQuality {
            quality -= 0.1
            data = jpegData(compressionQuality: quality) ?? data
        }

        return data
    }

    func resized(maxDimension: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension else { return self }

        let scale = maxDimension / largestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
