import SwiftUI
import UIKit
import Combine

/// Hält eine Referenz auf die aktive Zeichenfläche, damit die umgebende View
/// die Unterschrift exportieren oder löschen kann.
final class SignaturePadController: ObservableObject {
    @Published var isEmpty: Bool = true
    fileprivate weak var drawView: SignatureDrawView?E

    func clear() {
        drawView?.clear()
    }

    func exportPNGData() -> Data? {
        drawView?.exportImage().pngData()
    }
}

/// Großes weißes Unterschriftsfeld, optimiert für Querformat.
struct SignaturePad: UIViewRepresentable {
    @ObservedObject var controller: SignaturePadController

    func makeUIView(context: Context) -> SignatureDrawView {
        let view = SignatureDrawView()
        view.backgroundColor = .white
        view.onStrokeChanged = { isEmpty in
            DispatchQueue.main.async {
                controller.isEmpty = isEmpty
            }
        }
        controller.drawView = view
        return view
    }

    func updateUIView(_ uiView: SignatureDrawView, context: Context) {}
}

final class SignatureDrawView: UIView {
    private var paths: [UIBezierPath] = []
    private var currentPath: UIBezierPath?
    var onStrokeChanged: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isMultipleTouchEnabled = false
    }

    func clear() {
        paths.removeAll()
        currentPath = nil
        setNeedsDisplay()
        onStrokeChanged?(true)
    }

    func exportImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(bounds)
            UIColor.black.setStroke()
            for path in paths {
                path.stroke()
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let path = UIBezierPath()
        path.lineWidth = 3
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: point)
        currentPath = path
        paths.append(path)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self), let currentPath else { return }
        currentPath.addLine(to: point)
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentPath = nil
        onStrokeChanged?(paths.isEmpty)
    }

    override func draw(_ rect: CGRect) {
        UIColor.white.setFill()
        UIRectFill(rect)
        UIColor.black.setStroke()
        for path in paths {
            path.stroke()
        }
    }
}
