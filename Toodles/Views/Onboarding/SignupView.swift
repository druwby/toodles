import SwiftUI

struct SignupView: View {
    @ObservedObject var viewModel: UserViewModel

    var body: some View {
        ZStack {
            AmbientOrbBackground(intensity: .heavy)

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 2)
                        Text("Create your account")
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(.white)
                        Text("Use your @csu.fullerton.edu or @fullerton.edu email")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 16)

                    VStack(spacing: 14) {
                        // Email + domain chips
                        VStack(spacing: 0) {
                            TextField("", text: $viewModel.email, prompt: Text("Email").foregroundStyle(.gray))
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .foregroundStyle(.black)
                                .tint(.black)
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

                        // First + Last name — matches Hinge/Tinder convention.
                        HStack(spacing: 10) {
                            TextField("", text: $viewModel.firstName, prompt: Text("First name").foregroundStyle(.gray))
                                .textContentType(.givenName)
                                .foregroundStyle(.black)
                                .tint(.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            TextField("", text: $viewModel.lastName, prompt: Text("Last name").foregroundStyle(.gray))
                                .textContentType(.familyName)
                                .foregroundStyle(.black)
                                .tint(.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        SecureField("", text: $viewModel.password, prompt: Text("Password (min 8 chars)").foregroundStyle(.gray))
                            .textContentType(.newPassword)
                            .foregroundStyle(.black)
                            .tint(.black)
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
                        viewModel.signup()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Create Account")
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
                    .disabled(!formValid)
                    .opacity(formValid ? 1 : 0.5)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 24)
                }
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

    private var formValid: Bool {
        !viewModel.email.isEmpty &&
        !viewModel.password.isEmpty &&
        viewModel.password.count >= 8 &&
        !viewModel.firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !viewModel.lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
