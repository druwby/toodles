import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: UserViewModel

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .cyan.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Welcome back")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 40)

                // Email field + domain suggestion chips (same pattern as SignupView)
                VStack(spacing: 0) {
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Chips appear once user types "@" but hasn't finished the domain
                    if viewModel.email.contains("@") && !viewModel.email.hasSuffix(".edu") {
                        HStack(spacing: 8) {
                            domainChip("@csu.fullerton.edu")
                            domainChip("@fullerton.edu")
                        }
                        .padding(.top, 8)
                    }
                }

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if let err = viewModel.errorMessage {
                    Text(err)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button("Sign In") {
                    viewModel.login()
                }
                .buttonStyle(ToodlesPrimaryButtonStyle())
                .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func domainChip(_ domain: String) -> some View {
        Button {
            if let atIndex = viewModel.email.firstIndex(of: "@") {
                viewModel.email = String(viewModel.email[viewModel.email.startIndex..<atIndex]) + domain
            } else {
                viewModel.email += domain
            }
        } label: {
            Text(domain)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ToodlesTheme.headerBlue)
                .clipShape(Capsule())
        }
    }
}
