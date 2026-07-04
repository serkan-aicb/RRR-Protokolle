import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case username, password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing) {
                Spacer(minLength: 60)

                VStack(spacing: 12) {
                    Image("CompanyLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 260)
                    Text("Protokolle")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(spacing: 16) {
                    LabeledTextField(title: "Benutzername", text: $authViewModel.usernameInput, autocapitalization: .never)
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Passwort")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        SecureField("Passwort", text: $authViewModel.passwordInput)
                            .font(Theme.fieldFont)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .frame(height: Theme.buttonHeight)
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { authViewModel.login() }
                    }

                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }

                    PrimaryButton(title: "Anmelden") {
                        focusedField = nil
                        authViewModel.login()
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, Theme.spacing)

                Spacer()
            }
            .padding(.bottom, 40)
        }
        .background(Theme.background)
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    LoginView().environmentObject(AuthViewModel())
}
