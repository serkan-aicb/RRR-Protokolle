import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.spacing) {
                Image("CompanyLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200)
                    .padding(.top, 24)

                Spacer()

                if let user = authViewModel.currentUser {
                    Text("Hi \(user.firstName)!")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()

                VStack(spacing: 20) {
                    NavigationLink {
                        if let user = authViewModel.currentUser {
                            NewOrderFlowView(user: user)
                        }
                    } label: {
                        MenuCard(title: "Neuer Auftrag", systemImage: "doc.badge.plus")
                    }

                    NavigationLink {
                        if let user = authViewModel.currentUser {
                            CompletedOrdersListView(user: user)
                        }
                    } label: {
                        MenuCard(title: "Abgeschlossene Aufträge", systemImage: "checkmark.circle")
                    }

                    NavigationLink {
                        ProfileView()
                    } label: {
                        MenuCard(title: "Profil", systemImage: "person.crop.circle")
                    }
                }
                .padding(.horizontal, Theme.spacing)

                Spacer()
                Spacer()
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
        }
    }
}

private struct MenuCard: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 34))
                .frame(width: 56)
                .foregroundStyle(Theme.accent)

            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

#Preview {
    MainMenuView().environmentObject(AuthViewModel())
}
