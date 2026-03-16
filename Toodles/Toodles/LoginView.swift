//
//  LoginView.swift
//  Toodles
//
//  Created by Vincent Polanco on 3/3/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var showResetPassword = false

    var body: some View {
        VStack(spacing: 20) {
            Text(isSignUp ? "Sign Up" : "Sign In")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if isSignUp {
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            if !authManager.errorMessage.isEmpty {
                Text(authManager.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            if !authManager.successMessage.isEmpty {
                Text(authManager.successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            Button(isSignUp ? "Sign Up" : "Sign In") {
                if isSignUp {
                    guard password == confirmPassword else {
                        authManager.errorMessage = "Passwords do not match."
                        return
                    }
                    authManager.signUp(email: email, password: password)
                } else {
                    authManager.signIn(email: email, password: password)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(authManager.isLoading)

            if !isSignUp {
                Button("Forgot Password?") {
                    showResetPassword = true
                }
                .font(.caption)
            }

            Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                isSignUp.toggle()
                authManager.errorMessage = ""
                authManager.successMessage = ""
            }
            .font(.caption)
        }
        .padding()
        .alert("Reset Password", isPresented: $showResetPassword) {
            TextField("Email", text: $email)
            Button("Send Reset Link") {
                authManager.resetPassword(email: email)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your email to receive a password reset link.")
        }
    }
}
