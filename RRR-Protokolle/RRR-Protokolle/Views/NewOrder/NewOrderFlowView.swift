import SwiftUI

/// Container für den mehrstufigen Auftrags-Wizard. Der Zustand wird
/// ausschließlich im gemeinsamen NewOrderViewModel gehalten, damit beim
/// Wechseln der Schritte keine Eingaben verloren gehen.
struct NewOrderFlowView: View {
    @StateObject private var viewModel: NewOrderViewModel

    init(user: User) {
        _viewModel = StateObject(wrappedValue: NewOrderViewModel(user: user))
    }

    var body: some View {
        Group {
            switch viewModel.step {
            case .customerData:
                CustomerDataStepView(viewModel: viewModel)
            case .camera:
                CameraStepView(viewModel: viewModel)
            case .text:
                TextStepView(viewModel: viewModel)
            case .signature:
                SignatureStepView(viewModel: viewModel)
            }
        }
        .navigationBarBackButtonHidden(viewModel.step != .customerData)
    }
}
