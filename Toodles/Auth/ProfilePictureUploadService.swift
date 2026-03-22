import Foundation
import FirebaseStorage
import UIKit
import Combine

// TDV-64: Implement profile picture upload to Firebase Storage
// Handles image compression, upload progress, and download URL retrieval

class ProfilePictureUploadService: ObservableObject {
    
    private let storage = Storage.storage()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading: Bool = false
    @Published var uploadError: Error?
    
    // MARK: - Upload profile picture to Firebase Storage
    func uploadProfilePicture(image: UIImage, userId: String) -> AnyPublisher<URL, Error> {
        return Future<URL, Error> { [weak self] promise in
            guard let self = self else { return }
            
            guard let imageData = image.jpegData(compressionQuality: 0.75) else {
                promise(.failure(UploadError.imageCompressionFailed))
                return
            }
            
            let storageRef = self.storage.reference()
            let profilePicRef = storageRef.child("profile_pictures/\(userId)/profile.jpg")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            self.isUploading = true
            
            let uploadTask = profilePicRef.putData(imageData, metadata: metadata) { metadata, error in
                self.isUploading = false
                
                if let error = error {
                    self.uploadError = error
                    promise(.failure(error))
                    return
                }
                
                profilePicRef.downloadURL { url, error in
                    if let error = error {
                        promise(.failure(error))
                    } else if let url = url {
                        promise(.success(url))
                    }
                }
            }
            
            uploadTask.observe(.progress) { [weak self] snapshot in
                let percentComplete = Double(snapshot.progress!.completedUnitCount) /
                    Double(snapshot.progress!.totalUnitCount)
                DispatchQueue.main.async {
                    self?.uploadProgress = percentComplete
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Delete existing profile picture
    func deleteProfilePicture(userId: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else { return }
            
            let storageRef = self.storage.reference()
            let profilePicRef = storageRef.child("profile_pictures/\(userId)/profile.jpg")
            
            profilePicRef.delete { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    enum UploadError: LocalizedError {
        case imageCompressionFailed
        
        var errorDescription: String? {
            switch self {
            case .imageCompressionFailed:
                return "Failed to compress image for upload."
            }
        }
    }
}
