import SwiftUI

struct CameraStepView: View {
    @ObservedObject var viewModel: NewOrderViewModel
    @StateObject private var camera = CameraController()
    @State private var showCapturedPreview = false
    @State private var baseZoomFactor: CGFloat = 1.0

    var body: some View {
        ZStack {
            if camera.isSessionReady {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                camera.setZoom(baseZoomFactor * value)
                            }
                            .onEnded { _ in
                                baseZoomFactor = camera.zoomFactor
                            }
                    )
            } else {
                Color.black.ignoresSafeArea()
                ProgressView().tint(.white)
            }

            if showCapturedPreview, let image = camera.lastCapturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            VStack {
                topBar
                Spacer()
                if !showCapturedPreview {
                    bottomBar
                }
            }
            .padding()
        }
        .statusBarHidden()
        .onAppear { camera.requestAccessAndConfigure() }
        .onDisappear { camera.stop() }
        .alert("Kamera", isPresented: .constant(camera.errorMessage != nil), actions: {
            Button("OK") { camera.errorMessage = nil }
        }, message: {
            Text(camera.errorMessage ?? "")
        })
    }

    private var topBar: some View {
        HStack {
            Button {
                camera.stop()
                viewModel.backToCustomerData()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.4), in: Circle())
            }

            Spacer()

            Button {
                camera.toggleFlash()
            } label: {
                Image(systemName: camera.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.4), in: Circle())
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 16) {
            if !viewModel.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(viewModel.images.enumerated()), id: \.offset) { _, image in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .frame(height: 56)
            }

            HStack {
                Text("\(viewModel.images.count) Foto(s)")
                    .foregroundStyle(.white)
                    .font(.subheadline)

                Spacer()

                Button {
                    capturePhoto()
                } label: {
                    Circle()
                        .fill(.white)
                        .frame(width: 76, height: 76)
                        .overlay(Circle().stroke(.black.opacity(0.2), lineWidth: 2).padding(4))
                }

                Spacer()

                Button {
                    camera.stop()
                    viewModel.goToText()
                } label: {
                    Text("Weiter")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private func capturePhoto() {
        camera.capturePhoto { image in
            viewModel.addCapturedImage(image)
            PhotoLibraryService.save(image)
            withAnimation { showCapturedPreview = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showCapturedPreview = false }
            }
        }
    }
}
