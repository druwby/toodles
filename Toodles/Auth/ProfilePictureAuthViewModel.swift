// TDV-39: Implement profile picture authentication system
// ProfilePictureAuthViewModel.swift
// Toodles
//
// ViewModel driving the profile picture authentication flow.

import Foundation
import Combine

final class ProfilePictureAuthViewModel: ObservableObject {
    
    @Published var authStatus: ProfilePictureAuthStatus = .pending
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var requiresManualReview: Bool = false
    
    private let authService: ProfilePictureAuthService
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: ProfilePictureAuthService = .shared) {
        self.authService = authService
        authService.$authStatus.receive(on: DispatchQueue.main).assign(to: \.authStatus, on: self).store(in: &cancellables)
        authService.$isProcessing.receive(on: DispatchQueue.main).assign(to: \.isLoading, on: self).store(in: &cancellables)
    }
    
    func loadStatus(for userId: String) {
        authService.fetchVerificationStatus(userId: userId) { [weak self] status in
            DispatchQueue.main.async { self?.authStatus = status }
        }
    }
    
    func submitVerification(imageData: Data, userId: String) {
        guard let image = UIImage(data: imageData) else { errorMessage = "Invalid image data."; return }
        errorMessage = nil; successMessage = nil
        authService.uploadAndVerify(image: image, userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let authResult):
                    self?.authStatus = authResult.status
                    self?.requiresManualReview = authResult.requiresManualReview
                    self?.successMessage = authResult.message
                case .failure(let error): self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    var statusDisplayText: String {
        switch authStatus {
        case .pending: return "Verification Pending"
        case .verified: return "Photo Verified"
        case .rejected: return "Verification Failed"
        case .requiresReview: return "Under Review"
        }
    }
    
    var statusColor: String {
        switch authStatus {
        case .pending: return "gray"
        case .verified: return "green"
        case .rejected: return "red"
        case .requiresReview: return "orange"
        }
    }
    
    var isVerified: Bool { authStatus == .verified }
}
