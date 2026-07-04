import SwiftUI

/// Übersichtliche kleine Galerie mit mehreren Bildern pro Zeile.
struct ImageThumbnailGrid: View {
    let images: [UIImage]
    var onDelete: ((Int) -> Void)? = nil

    private let columns = [GridItem(.adaptive(minimum: 84, maximum: 110), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    if let onDelete {
                        Button {
                            onDelete(index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white, .black.opacity(0.6))
                                .font(.title3)
                        }
                        .padding(4)
                    }
                }
            }
        }
    }
}
