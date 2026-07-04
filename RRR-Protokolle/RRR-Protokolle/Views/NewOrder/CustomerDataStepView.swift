import SwiftUI

struct CustomerDataStepView: View {
    @ObservedObject var viewModel: NewOrderViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LabeledTextField(title: "Firma", text: $viewModel.draft.customer.company)
                LabeledTextField(title: "Vorname", text: $viewModel.draft.customer.firstName)
                LabeledTextField(title: "Nachname", text: $viewModel.draft.customer.lastName)
                LabeledTextField(title: "Adresse", text: $viewModel.draft.customer.address)
                LabeledTextField(title: "Stadt", text: $viewModel.draft.customer.city)

                PrimaryButton(title: "Weiter", systemImage: "arrow.right", isEnabled: viewModel.draft.customer.isValid) {
                    viewModel.goToCamera()
                }
                .padding(.top, 12)
            }
            .padding(Theme.spacing)
        }
        .background(Theme.background)
        .navigationTitle("Kundendaten")
        .navigationBarTitleDisplayMode(.inline)
    }
}
