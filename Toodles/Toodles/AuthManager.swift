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
    @Published var user: User?
    @Published var isSignedIn = false
    @Published var isAdmin = false
    @Published var errorMessage = ""
    
    // Add your allowed email domains here
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
    
    // Validate email domain
    func isValidEmailDomain(_ email: String) -> Bool {
        let domain = email.lowercased().components(separatedBy: "@").last ?? ""
        return allowedDomains.contains(domain)
    }
    
    // Sign Up with domain check
    func signUp(email: String, password: String) {
        // Check domain first
        guard isValidEmailDomain(email) else {
            self.errorMessage = "Please use your school email (@csu.fullerton.edu)"
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                // Send verification email
                result?.user.sendEmailVerification { error in
                    if let error = error {
                        self.errorMessage = "Account created but failed to send verification email: \(error.localizedDescription)"
                    } else {
                        self.errorMessage = "Account created! Please check your email to verify your account."
                    }
                }
            }
        }
    }
    
    // Sign In - also verify email is confirmed
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if result?.user.isEmailVerified == false {
                self.errorMessage = "Please verify your email first. Check your inbox."
                try? Auth.auth().signOut()
            }
        }
    }
    
    // Call this after sign in
    func checkAdminStatus() {
        guard let uid = user?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error checking admin status: \(error.localizedDescription)")
                self.isAdmin = false
            } else if let document = document, document.exists {
                self.isAdmin = document.data()?["isAdmin"] as? Bool ?? false
            } else {
                // Document doesn't exist, user is not admin
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
