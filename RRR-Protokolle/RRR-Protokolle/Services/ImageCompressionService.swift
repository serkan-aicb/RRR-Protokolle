import UIKit

/// Optimiert Fotos für die Dokumentation, damit E-Mail inklusive PDF und
/// Bildanhängen möglichst unter 20 MB bleibt, ohne die Bildqualität für
/// Dokumentationszwecke unbrauchbar zu machen.
enum ImageCompressionService {
    private static let maxDimension: CGFloat = 1600
    private static let maxBytesPerImage = 900_000

    static func optimizedJPEGData(from image: UIImage) -> Data {
        let resized = image.resized(maxDimension: maxDimension)
        return resized.compressedJPEGData(maxBytes: maxBytesPerImage)
    }
}
