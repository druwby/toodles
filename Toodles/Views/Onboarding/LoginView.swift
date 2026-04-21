import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: UserViewModel

    var body: some View {
        ZStack {
            AmbientOrbBackground(intensity: .heavy)

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 2)
                    Text("Welcome back")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(.white)
                    Text("Sign in to your CSUF account")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.top, 40)

                VStack(spacing: 14) {
                    VStack(spacing: 0) {
                        TextField("", text: $viewModel.email, prompt: Text("Email").foregroundStyle(.gray))
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if viewModel.email.contains("@") && !viewModel.email.hasSuffix(".edu") {
                            HStack(spacing: 8) {
                                domainChip("@csu.fullerton.edu")
                                domainChip("@fullerton.edu")
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                    }

                    SecureField("", text: $viewModel.password, prompt: Text("Password").foregroundStyle(.gray))
                        .textContentType(.password)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)

                if let err = viewModel.errorMessage {
                    Text(err)
                        .font(.callout)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 24)
                }

                Button {
                    viewModel.login()
                } label: {
                    HStack(spacing: 8) {
                        Text("Sign In")
                            .font(.title3.bold())
                        Image(systemName: "arrow.right")
                            .font(.body.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.58, blue: 0.12),
                                Color(red: 0.98, green: 0.42, blue: 0.40)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(red: 0.98, green: 0.45, blue: 0.30).opacity(0.55), radius: 14, y: 8)
                }
                .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty)
                .opacity((viewModel.email.isEmpty || viewModel.password.isEmpty) ? 0.5 : 1)
                .padding(.horizontal, 24)

                Spacer()
            }
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
                .background(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
    }
}
