import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: Theme.spacing) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.accent)
                .padding(.top, 40)

            if let user = authViewModel.currentUser {
                VStack(spacing: 12) {
                    ProfileRow(label: "Vorname", value: user.firstName)
                    ProfileRow(label: "Nachname", value: user.lastName)
                    ProfileRow(label: "Position", value: user.position)
                }
                .padding(Theme.spacing)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .padding(.horizontal, Theme.spacing)
            }

            Spacer()

            PrimaryButton(title: "Abmelden", systemImage: "rectangle.portrait.and.arrow.right") {
                authViewModel.logout()
            }
            .padding(.horizontal, Theme.spacing)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfileRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.title3)
    }
}

#Preview {
    NavigationStack {
        ProfileView().environmentObject(AuthViewModel())
    }
}
