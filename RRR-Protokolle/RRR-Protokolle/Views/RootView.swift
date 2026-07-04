import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        if authViewModel.isLoggedIn {
            MainMenuView()
        } else {
            LoginView()
        }
    }
}

#Preview {
    RootView().environmentObject(AuthViewModel())
}
