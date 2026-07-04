import Photos
import UIKit

/// Sichert zusätzlich zur App-internen Ablage eine Kopie jedes aufgenommenen
/// Fotos in der normalen Fotomediathek des iPhones (nur Hinzufügen-Rechte,
/// kein Lesezugriff auf vorhandene Fotos nötig).
enum PhotoLibraryService {
    static func save(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        }
    }
}
