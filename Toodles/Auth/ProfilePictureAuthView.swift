// TDV-39: Implement profile picture authentication system
// ProfilePictureAuthView.swift
// Toodles
//
// SwiftUI view for the profile picture verification onboarding flow.

import SwiftUI
import PhotosUI

struct ProfilePictureAuthView: View {
    
    @StateObject private var authService = ProfilePictureAuthService.shared
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showResult = false
    @State private var authResult: ProfilePictureAuthResult?
    
    let userId: String
    var onComplete: ((ProfilePictureAuthStatus) -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                Text("Verify Your Profile Photo")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("We need to verify that your profile photo shows your real face.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 160)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
            } else {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 160, height: 160)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                    )
            }
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label(selectedImage == nil ? "Choose Photo" : "Change Photo", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            Button(action: submitForVerification) {
                Text("Submit for Verification")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedImage != nil ? Color.blue : Color(.systemGray4))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(selectedImage == nil || authService.isProcessing)
            Spacer()
        }
        .padding()
        .navigationTitle("Photo Verification")
    }
    
    private func submitForVerification() {
        guard let image = selectedImage else { return }
        authService.uploadAndVerify(image: image, userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let authResult):
                    self.authResult = authResult
                    self.onComplete?(authResult.status)
                case .failure(let error):
                    print("Verification failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
