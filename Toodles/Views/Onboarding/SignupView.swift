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

                    Group {
                        TextField("Email", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

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

    private var formValid: Bool {
        !viewModel.email.isEmpty &&
        !viewModel.password.isEmpty &&
        viewModel.password.count >= 8 &&
        !viewModel.displayName.isEmpty
    }
}
