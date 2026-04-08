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

                Group {
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                }
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
}
