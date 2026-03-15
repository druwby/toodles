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
    @State private var isSignUp = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isSignUp ? "Sign Up" : "Sign In")
                .font(.largeTitle)
                .bold()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !authManager.errorMessage.isEmpty {
                Text(authManager.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(isSignUp ? "Sign Up" : "Sign In") {
                if isSignUp {
                    authManager.signUp(email: email, password: password)
                } else {
                    authManager.signIn(email: email, password: password)
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                isSignUp.toggle()
            }
            .font(.caption)
        }
        .padding()
    }
}
