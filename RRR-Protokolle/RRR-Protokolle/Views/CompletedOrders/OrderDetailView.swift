import SwiftUI

struct OrderDetailView: View {
    let order: Order

    private var images: [UIImage] {
        order.imageFileNames.compactMap { fileName in
            UIImage(contentsOfFile: LocalStorageService.shared.imageURL(fileName: fileName, for: order).path)
        }
    }

    private var pdfData: Data? {
        LocalStorageService.shared.loadPDFData(for: order) ?? {
            let data = PDFService.generate(order: order)
            return data
        }()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.customer.company)
                        .font(.title2.bold())
                    Text("\(order.customer.firstName) \(order.customer.lastName)")
                    Text("\(order.customer.address), \(order.customer.city)")
                    Text(order.createdAt.germanDateString)
                        .foregroundStyle(.secondary)
                }

                if !order.text.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Auftragstext")
                            .font(.headline)
                        Text(order.text)
                    }
                }

                if !images.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Fotos")
                            .font(.headline)
                        ImageThumbnailGrid(images: images)
                    }
                }

                if let pdfData {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PDF-Vorschau")
                            .font(.headline)
                        PDFPreviewView(data: pdfData)
                            .frame(height: 500)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                    }
                }
            }
            .padding(Theme.spacing)
        }
        .background(Theme.background)
        .navigationTitle("Auftrag")
        .navigationBarTitleDisplayMode(.inline)
    }
}
