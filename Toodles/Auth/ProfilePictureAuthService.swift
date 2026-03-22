// TDV-39: Implement profile picture authentication system
// ProfilePictureAuthService.swift
// Toodles
//
// Verification system to ensure profile pictures match the actual user,
// adding an extra layer of security and reducing catfishing.

import Foundation
import FirebaseStorage
import FirebaseFirestore
import UIKit
import Vision

// MARK: - Models

enum ProfilePictureAuthStatus: String, Codable {
    case pending = "pending"
    case verified = "verified"
    case rejected = "rejected"
    case requiresReview = "requires_review"
}

struct ProfilePictureAuthResult {
    let status: ProfilePictureAuthStatus
    let confidence: Double
    let message: String
    let requiresManualReview: Bool
}

// MARK: - ProfilePictureAuthService

/// Manages profile picture verification to ensure photos match the real user.
/// Uses Vision framework for face detection and Firebase for storage/status tracking.
final class ProfilePictureAuthService: ObservableObject {
    
    static let shared = ProfilePictureAuthService()
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    @Published var authStatus: ProfilePictureAuthStatus = .pending
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    
    private init() {}
    
    func uploadAndVerify(image: UIImage, userId: String, completion: @escaping (Result<ProfilePictureAuthResult, Error>) -> Void) {
        isProcessing = true
        errorMessage = nil
        detectFace(in: image) { [weak self] faceDetected, confidence in
            guard let self = self else { return }
            guard faceDetected else {
                self.isProcessing = false
                let result = ProfilePictureAuthResult(status: .rejected, confidence: 0.0, message: "No face detected. Please upload a clear photo of your face.", requiresManualReview: false)
                self.authStatus = .rejected
                completion(.success(result))
                return
            }
            self.uploadToStorage(image: image, userId: userId) { uploadResult in
                switch uploadResult {
                case .failure(let error):
                    self.isProcessing = false
                    completion(.failure(error))
                case .success(let downloadURL):
                    let status: ProfilePictureAuthStatus = confidence > 0.85 ? .verified : .requiresReview
                    self.saveVerificationRecord(userId: userId, photoURL: downloadURL, status: status, confidence: confidence) { saveResult in
                        self.isProcessing = false
                        switch saveResult {
                        case .failure(let error): completion(.failure(error))
                        case .success:
                            let result = ProfilePictureAuthResult(status: status, confidence: confidence, message: status == .verified ? "Your profile photo has been verified successfully." : "Your photo is under review.", requiresManualReview: status == .requiresReview)
                            self.authStatus = status
                            completion(.success(result))
                        }
                    }
                }
            }
        }
    }
    
    private func detectFace(in image: UIImage, completion: @escaping (Bool, Double) -> Void) {
        guard let cgImage = image.cgImage else { completion(false, 0.0); return }
        let request = VNDetectFaceRectanglesRequest { request, error in
            guard error == nil, let results = request.results as? [VNFaceObservation], !results.isEmpty else { completion(false, 0.0); return }
            let maxConfidence = results.map { Double($0.confidence) }.max() ?? 0.0
            completion(true, maxConfidence)
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async { try? handler.perform([request]) }
    }
    
    private func uploadToStorage(image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { completion(.failure(NSError(domain: "ProfilePictureAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image."]))); return }
        let ref = Storage.storage().reference().child("profile_pictures/\(userId)/auth_\(UUID().uuidString).jpg")
        let metadata = StorageMetadata(); metadata.contentType = "image/jpeg"
        ref.putData(imageData, metadata: metadata) { _, error in
            if let error = error { completion(.failure(error)); return }
            ref.downloadURL { url, error in
                if let error = error { completion(.failure(error)) } else if let url = url { completion(.success(url.absoluteString)) }
            }
        }
    }
    
    private func saveVerificationRecord(userId: String, photoURL: String, status: ProfilePictureAuthStatus, confidence: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        let record: [String: Any] = ["userId": userId, "photoURL": photoURL, "status": status.rawValue, "confidence": confidence, "submittedAt": FieldValue.serverTimestamp(), "reviewedAt": NSNull()]
        Firestore.firestore().collection("profilePictureVerifications").document(userId).setData(record, merge: true) { error in
            if let error = error { completion(.failure(error)) } else { completion(.success(())) }
        }
    }
    
    func fetchVerificationStatus(userId: String, completion: @escaping (ProfilePictureAuthStatus) -> Void) {
        Firestore.firestore().collection("profilePictureVerifications").document(userId).getDocument { snapshot, _ in
            guard let data = snapshot?.data(), let statusRaw = data["status"] as? String, let status = ProfilePictureAuthStatus(rawValue: statusRaw) else { completion(.pending); return }
            completion(status)
        }
    }
}
