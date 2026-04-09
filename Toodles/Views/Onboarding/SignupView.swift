import SwiftUI

struct SignupView: View {
    @ObservedObject var viewModel: UserViewModel

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .cyan.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Create your account")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .padding(.top, 40)

                    Text("Use your @csu.fullerton.edu or @fullerton.edu email")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)

                    // Email field with domain autofill
                    VStack(spacing: 0) {
                        TextField("Email", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Domain suggestion chips — appear when @ is typed
                        if viewModel.email.contains("@") && !viewModel.email.hasSuffix(".edu") {
                            HStack(spacing: 8) {
                                domainChip("@csu.fullerton.edu")
                                domainChip("@fullerton.edu")
                            }
                            .padding(.top, 8)
                        }
                    }

                    Group {
                        TextField("Display name", text: $viewModel.displayName)
                            .textContentType(.name)

                        SecureField("Password (min 8 chars)", text: $viewModel.password)
                            .textContentType(.newPassword)
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }

                    Button("Create Account") {
                        viewModel.signup()
                    }
                    .buttonStyle(ToodlesPrimaryButtonStyle())
                    .disabled(!formValid)
                    .opacity(formValid ? 1 : 0.5)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func domainChip(_ domain: String) -> some View {
        Button {
            // Replace everything after @ with the selected domain
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

    private var formValid: Bool {
        !viewModel.email.isEmpty &&
        !viewModel.password.isEmpty &&
        viewModel.password.count >= 8 &&
        !viewModel.displayName.isEmpty
    }
}
