import SwiftUI

/// User profile screen.
/// TODO (TDV-38): Wire up save action to Firestore once backend is ready.
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    TextField("Display Name", text: $viewModel.displayName)
                    TextField("Bio", text: $viewModel.bio, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("Save Changes") {
                        viewModel.save()
                    }
                    .foregroundStyle(.pink)
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        appState.isLoggedIn = false
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
