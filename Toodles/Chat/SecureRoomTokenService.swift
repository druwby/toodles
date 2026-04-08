// SecureRoomTokenService.swift
// Toodles
// TDV-42: Develop "Start Chatting" logic to request a 60-second secure room token

import Foundation
import FirebaseFunctions
import FirebaseAuth

enum RoomTokenError: Error, LocalizedError {
    case notAuthenticated
    case functionCallFailed(String)
    case invalidResponse
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated."
        case .functionCallFailed(let msg):
            return "Room token request failed: \(msg)"
        case .invalidResponse:
            return "Invalid response from server."
        case .tokenExpired:
            return "The room token has expired."
        }
    }
}

struct SecureRoomToken {
    let token: String
    let roomURL: String
    let expiresAt: Date
    let sessionID: String

    var isExpired: Bool {
        Date() >= expiresAt
    }
}

@MainActor
class SecureRoomTokenService: ObservableObject {
    @Published var currentToken: SecureRoomToken? = nil
    @Published var isRequesting: Bool = false
    @Published var error: RoomTokenError? = nil

    private let functions = Functions.functions()
    private let tokenLifetime: TimeInterval = 60 // 60-second token

    /// Request a new 60-second secure room token from Firebase Cloud Functions
    func requestToken(matchID: String) async throws -> SecureRoomToken {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw RoomTokenError.notAuthenticated
        }

        isRequesting = true
        error = nil
        defer { isRequesting = false }

        do {
            let result = try await functions.httpsCallable("createSecureRoomToken").call([
                "matchID": matchID,
                "userUID": uid,
                "tokenLifetime": Int(tokenLifetime)
            ])

            guard
                let data = result.data as? [String: Any],
                let token = data["token"] as? String,
                let roomURL = data["roomURL"] as? String,
                let sessionID = data["sessionID"] as? String
            else {
                throw RoomTokenError.invalidResponse
            }

            let expiresAt = Date().addingTimeInterval(tokenLifetime)
            let secureToken = SecureRoomToken(
                token: token,
                roomURL: roomURL,
                expiresAt: expiresAt,
                sessionID: sessionID
            )
            currentToken = secureToken
            return secureToken

        } catch let error as RoomTokenError {
            self.error = error
            throw error
        } catch {
            let tokenError = RoomTokenError.functionCallFailed(error.localizedDescription)
            self.error = tokenError
            throw tokenError
        }
    }

    /// Validate that the current token is still active
    func validateCurrentToken() -> Bool {
        guard let token = currentToken else { return false }
        if token.isExpired {
            self.error = .tokenExpired
            currentToken = nil
            return false
        }
        return true
    }

    func clearToken() {
        currentToken = nil
        error = nil
    }
}
