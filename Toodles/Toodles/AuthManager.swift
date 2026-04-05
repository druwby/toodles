//
//  AuthManager.swift
//  Toodles
//
//  Created by Vincent Polanco on 3/3/26.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isSignedIn = false
    @Published var isAdmin = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""

    let allowedDomains = ["csu.fullerton.edu", "fullerton.edu"]

    init() {
        Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
            self.isSignedIn = user != nil

            if user != nil {
                self.checkAdminStatus()
            } else {
                self.isAdmin = false
                self.errorMessage = ""
            }
        }
    }

    func isValidEmailDomain(_ email: String) -> Bool {
        let domain = email.lowercased().components(separatedBy: "@").last ?? ""
        return allowedDomains.contains(domain)
    }

    func signUp(email: String, password: String) {
        guard isValidEmailDomain(email) else {
            self.errorMessage = "Please use your school email (@csu.fullerton.edu)"
            return
        }

        isLoading = true
        errorMessage = ""
        successMessage = ""

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            self.isLoading = false

            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }

            guard let firebaseUser = result?.user else { return }

            // Send verification email
            firebaseUser.sendEmailVerification { error in
                if let error = error {
                    self.errorMessage = "Account created but failed to send verification email: \(error.localizedDescription)"
                }
            }

            // Create Firestore user profile
            let db = Firestore.firestore()
            db.collection("users").document(firebaseUser.uid).setData([
                "userId": firebaseUser.uid,
                "eduEmail": email,
                "displayName": "",
                "bio": "",
                "toastScore": 100
            ]) { error in
                if let error = error {
                    print("Error creating user profile: \(error.localizedDescription)")
                }
            }

            // Sign out until email is verified
            self.successMessage = "Account created! Please check your email to verify your account."
            try? Auth.auth().signOut()
        }
    }

    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = ""
        successMessage = ""

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            self.isLoading = false

            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if result?.user.isEmailVerified == false {
                self.errorMessage = "Please verify your email first. Check your inbox."
                try? Auth.auth().signOut()
            }
        }
    }

    func resetPassword(email: String) {
        isLoading = true
        errorMessage = ""
        successMessage = ""

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            self.isLoading = false

            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.successMessage = "Password reset email sent. Check your inbox."
            }
        }
    }

    func checkAdminStatus() {
        guard let uid = user?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                self.isAdmin = document.data()?["isAdmin"] as? Bool ?? false
            } else {
                self.isAdmin = false
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
