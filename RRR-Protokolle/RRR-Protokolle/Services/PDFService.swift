import UIKit

/// Erzeugt das professionelle Auftragsprotokoll als PDF: Kopfbereich mit
/// Kunden- und Firmendaten, Auftragstext, Bildergalerie, Unterschrift und
/// Footer mit Impressumsdaten.
enum PDFService {
    private static let pageWidth: CGFloat = 595.2   // A4 @ 72dpi
    private static let pageHeight: CGFloat = 841.8
    private static let margin: CGFloat = 36

    static func generate(order: Order) -> Data {
        let images = order.imageFileNames.compactMap { fileName -> UIImage? in
            UIImage(contentsOfFile: LocalStorageService.shared.imageURL(fileName: fileName, for: order).path)
        }
        let signatureImage = UIImage(contentsOfFile: LocalStorageService.shared.signatureURL(for: order).path)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            var cursorY: CGFloat = 0
            beginPage(context: context, cursorY: &cursorY)

            drawHeader(order: order, context: context, cursorY: &cursorY)
            cursorY += 24

            drawMeta(order: order, context: context, cursorY: &cursorY)
            cursorY += 12

            drawText(order.text, context: context, cursorY: &cursorY)
            cursorY += 20

            if !images.isEmpty {
                drawSectionTitle("Fotos", context: context, cursorY: &cursorY)
                drawImageGallery(images, context: context, cursorY: &cursorY)
                cursorY += 12
            }

            if let signatureImage {
                drawSignature(signatureImage, context: context, cursorY: &cursorY)
            }

            drawFooter(order: order, context: context)
        }
    }

    // MARK: - Seitenverwaltung

    private static func beginPage(context: UIGraphicsPDFRendererContext, cursorY: inout CGFloat) {
        context.beginPage()
        cursorY = margin
    }

    private static func ensureSpace(_ needed: CGFloat, context: UIGraphicsPDFRendererContext, cursorY: inout CGFloat) {
        let maxY = pageHeight - margin - 40 // Platz für Footer
        if cursorY + needed > maxY {
            beginPage(context: context, cursorY: &cursorY)
        }
    }

    // MARK: - Kopfbereich

    private static func drawHeader(order: Order, context: UIGraphicsPDFRendererContext, cursorY: inout CGFloat) {
        let columnWidth = (pageWidth - margin * 2 - 20) / 2
        let leftRect = CGRect(x: margin, y: cursorY, width: columnWidth, height: 140)
        let rightRect = CGRect(x: margin + columnWidth + 20, y: cursorY, width: columnWidth, height: 140)

        let customerLines = [
            order.customer.company,
            "\(order.customer.firstName) \(order.customer.lastName)",
            order.customer.address,
            order.customer.city
        ].filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        drawTextBlock(lines: customerLines, in: leftRect, titleFont: .boldSystemFont(ofSize: 13), bodyFont: .systemFont(ofSize: 11))

        if let logo = UIImage(named: CompanyConfig.logoImageName) {
            let logoHeight: CGFloat = 36
            let logoWidth = logo.size.width / max(logo.size.height, 1) * logoHeight
            let logoRect = CGRect(x: rightRect.maxX - logoWidth, y: rightRect.minY, width: logoWidth, height: logoHeight)
            logo.draw(in: logoRect)
        }

        let companyLines = [
            CompanyConfig.name,
            CompanyConfig.addressLine1,
            CompanyConfig.addressLine2,
            CompanyConfig.phone,
            CompanyConfig.email
        ]
        let companyTextRect = CGRect(x: rightRect.minX, y: rightRect.minY + 44, width: rightRect.width, height: rightRect.height - 44)
        drawTextBlock(lines: companyLines, in: companyTextRect, titleFont: .boldSystemFont(ofSize: 13), bodyFont: .systemFont(ofSize: 11), alignment: .right)

        cursorY += 140
    }

    private static func drawTextBlock(lines: [String], in rect: CGRect, titleFont: UIFont, bodyFont: UIFont, alignment: NSTextAlignment = .left) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment

        var y = rect.minY
        for (index, line) in lines.enumerated() {
            let font = index == 0 ? titleFont : bodyFont
            let attributes: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: paragraphStyle]
            let lineRect = CGRect(x: rect.minX, y: y, width: rect.width, height: 18)
            (line as NSString).draw(in: lineRect, withAttributes: attributes)
            y += 16
        }
    }

    // MARK: - Meta (Datum, Monteur)

    private static func drawMeta(order: Order, context: UIGraphicsPDFRendererContext, cursorY: inout CGFloat) {
        ensureSpace(50, context: context, cursorY: &cursorY)

        let lines = [
            "Erstellungsdatum: \(order.createdAt.germanDateString)",
            "Monteur: \(order.monteurFullName) (\(order.monteurPosition))"
        ]
        for line in lines {
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11)]
            (line as NSString).draw(at: CGPoint(x: margin, y: cursorY), withAttributes: attributes)
            cursorY += 16
        }
    }

    // MARK: - Auftragstext

    private static func drawSectionTitle(_ title: String, context: UIGraphicsPDFRendererContext, cursorY: inout CGFloat) {
        ensureSpace(24, context: context, cursorY: &cursorY)
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 13)]
        (title as NSString).draw(at: CGPoint(x: margin, y: cursorY), withAttributes: attributes)
        cursorY += 20
    }

    private static func drawText(_ text: String, context: UIGraphicsPDFRendererContext, cursorY: inout CGFloat) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        drawSectionTitle("Auftragstext", context: context, cursorY: &cursorY)

        let font = UIFont.systemFont(ofSize: 11)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let contentWidth = pageWidth - margin * 2
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        ensureSpace(boundingRect.height, context: context, cursorY: &cursorY)
        let rect = CGRect(x: margin, y: cursorY, width: contentWidth, height: boundingRect.height)
        (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        cursorY += boundingRect.height
    }

    // MARK: - Bildergalerie

    private static func drawImageGallery(_ images: [UIImage], context: UIGraphicsPDFRendererContext, cursorY: inout CGFloat) {
        let columns = 3
        let spacing: CGFloat = 8
        let contentWidth = pageWidth - margin * 2
        let tileWidth = (contentWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        let tileHeight = tileWidth * 0.75

        var column = 0
        for image in images {
            ensureSpace(tileHeight + spacing, context: context, cursorY: &cursorY)

            let x = margin + CGFloat(column) * (tileWidth + spacing)
            let rect = CGRect(x: x, y: cursorY, width: tileWidth, height: tileHeight)
            drawAspectFilled(image, in: rect, context: context)

            column += 1
            if column == columns {
                column = 0
                cursorY += tileHeight + spacing
            }
        }
        if column != 0 {
            cursorY += tileHeight + spacing
        }
    }

    private static func drawAspectFilled(_ image: UIImage, in rect: CGRect, context: UIGraphicsPDFRendererContext) {
        let cgContext = context.cgContext
        cgContext.saveGState()
        cgContext.clip(to: rect)

        let imageSize = image.size
        let scale = max(rect.width / imageSize.width, rect.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let originX = rect.minX + (rect.width - scaledSize.width) / 2
        let originY = rect.minY + (rect.height - scaledSize.height) / 2
        image.draw(in: CGRect(origin: CGPoint(x: originX, y: originY), size: scaledSize))

        cgContext.restoreGState()
    }

    // MARK: - Unterschrift

    private static func drawSignature(_ image: UIImage, context: UIGraphicsPDFRendererContext, cursorY: inout CGFloat) {
        let width: CGFloat = 220
        let height = width * (image.size.height / max(image.size.width, 1))
        ensureSpace(height + 30, context: context, cursorY: &cursorY)

        let rect = CGRect(x: margin, y: cursorY, width: width, height: height)
        image.draw(in: rect)
        cursorY += height + 4

        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.italicSystemFont(ofSize: 10)]
        ("Kundenunterschrift" as NSString).draw(at: CGPoint(x: margin, y: cursorY), withAttributes: attributes)
        cursorY += 16
    }

    // MARK: - Footer

    private static func drawFooter(order: Order, context: UIGraphicsPDFRendererContext) {
        let footerText = "\(CompanyConfig.name) · \(order.createdAt.germanDateString) · \(CompanyConfig.impressum)"
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.darkGray]
        let rect = CGRect(x: margin, y: pageHeight - margin, width: pageWidth - margin * 2, height: 24)
        (footerText as NSString).draw(with: rect, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
    }
}
