import AVFoundation
import UIKit
import Combine

/// Steuert eine eigene Kamera-Session (statt des System-Bildpickers), damit
/// Blitz, Zoom und eine automatische Rückkehr zur Live-Ansicht nach jeder
/// Aufnahme frei gestaltet werden können.
@MainActor
final class CameraController: NSObject, ObservableObject {
    @Published var isFlashOn = false
    @Published var zoomFactor: CGFloat = 1.0
    @Published var isSessionReady = false
    @Published var lastCapturedImage: UIImage?
    @Published var errorMessage: String?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private let sessionQueue = DispatchQueue(label: "RRR.CameraController.session")

    var minZoomFactor: CGFloat { 1.0 }
    var maxZoomFactor: CGFloat { min(currentDevice?.activeFormat.videoMaxZoomFactor ?? 5, 5) }

    private var captureCompletion: ((UIImage) -> Void)?

    func requestAccessAndConfigure() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }
            Task { @MainActor in
                if granted {
                    self.configureSession()
                } else {
                    self.errorMessage = "Kamerazugriff wurde nicht erlaubt."
                }
            }
        }
    }

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                self.session.commitConfiguration()
                Task { @MainActor in self.errorMessage = "Kamera konnte nicht initialisiert werden." }
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            self.session.commitConfiguration()
            self.currentDevice = device
            self.session.startRunning()

            Task { @MainActor in
                self.isSessionReady = true
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func toggleFlash() {
        isFlashOn.toggle()
    }

    func setZoom(_ factor: CGFloat) {
        guard let device = currentDevice else { return }
        let clamped = max(minZoomFactor, min(factor, maxZoomFactor))
        sessionQueue.async {
            try? device.lockForConfiguration()
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
        }
        zoomFactor = clamped
    }

    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        if let device = currentDevice, device.hasFlash {
            settings.flashMode = isFlashOn ? .on : .off
        }
        sessionQueue.async { [weak self] in
            self?.photoOutput.capturePhoto(with: settings, delegate: self ?? AVCapturePhotoCaptureDelegateStub())
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        Task { @MainActor in
            self.lastCapturedImage = image
            self.captureCompletion?(image)
        }
    }
}

/// Fallback-Delegate, falls die Session vor der ersten Aufnahme bereits
/// freigegeben wurde (verhindert einen erzwungenen Optional-Unwrap).
private final class AVCapturePhotoCaptureDelegateStub: NSObject, AVCapturePhotoCaptureDelegate {}
