import Foundation
import FirebaseStorage
import UIKit

final class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()
    private init() {}

    func uploadProfilePhoto(uid: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "StorageService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not encode image as JPEG."
            ])))
            return
        }
        let path = "users/\(uid)/profile/\(Int(Date().timeIntervalSince1970)).jpg"
        let ref = storage.reference(withPath: path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        ref.putData(data, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            ref.downloadURL { url, error in
                if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(error ?? NSError(domain: "StorageService", code: 2)))
                }
            }
        }
    }
}
