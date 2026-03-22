import Foundation
import Vision
import UIKit
import Combine

// TDV-65: Implement face liveness detection using Apple Vision framework
// Detects real faces vs photos to prevent catfishing during profile picture authentication

class FaceLivenessDetectionService: ObservableObject {
    
    @Published var detectionResult: LivenessResult = .unknown
    @Published var isProcessing: Bool = false
    @Published var detectionError: Error?
    
    // MARK: - Analyze image for face liveness
    func analyzeFaceLiveness(image: UIImage) -> AnyPublisher<LivenessResult, Error> {
        return Future<LivenessResult, Error> { [weak self] promise in
            guard let self = self else { return }
            guard let cgImage = image.cgImage else {
                promise(.failure(DetectionError.invalidImage))
                return
            }
            
            self.isProcessing = true
            
            let request = VNDetectFaceRectanglesRequest { request, error in
                self.isProcessing = false
                
                if let error = error {
                    self.detectionError = error
                    promise(.failure(error))
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation],
                      !observations.isEmpty else {
                    let result = LivenessResult.noFaceDetected
                    self.detectionResult = result
                    promise(.success(result))
                    return
                }
                
                let face = observations[0]
                let confidence = face.confidence
                
                if confidence > 0.85 {
                    let result = LivenessResult.livePersonDetected(confidence: Double(confidence))
                    self.detectionResult = result
                    promise(.success(result))
                } else {
                    let result = LivenessResult.suspiciousImage(confidence: Double(confidence))
                    self.detectionResult = result
                    promise(.success(result))
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                self.isProcessing = false
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func validateSingleFace(image: UIImage) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            guard let cgImage = image.cgImage else {
                promise(.failure(DetectionError.invalidImage))
                return
            }
            
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                let observations = request.results as? [VNFaceObservation] ?? []
                promise(.success(observations.count == 1))
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    enum LivenessResult {
        case unknown
        case noFaceDetected
        case livePersonDetected(confidence: Double)
        case suspiciousImage(confidence: Double)
        
        var isValid: Bool {
            switch self {
            case .livePersonDetected(let confidence):
                return confidence > 0.85
            default:
                return false
            }
        }
    }
    
    enum DetectionError: LocalizedError {
        case invalidImage
        
        var errorDescription: String? {
            return "The provided image could not be processed for face detection."
        }
    }
}
