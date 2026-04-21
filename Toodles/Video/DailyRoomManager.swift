// DailyRoomManager.swift
// Toodles
//
// TDV-70: Implement DailyRoomManager for room creation and teardown
// Updated: Added retry logic with exponential back-off for createRoom and joinRoom
// Parent: TDV-41 - Integrate Daily SDK for peer-to-peer video calling

import Foundation
import Daily

/// Manages the lifecycle of Daily.co video rooms including creation, joining, and teardown.
class DailyRoomManager: ObservableObject {

    @Published var isInRoom: Bool = false
    @Published var roomURL: URL?
    @Published var errorMessage: String?

    private let callClient: CallClient
    private var roomToken: String?

    /// Maximum number of retry attempts for network operations.
    private let maxRetries = 3
    /// Base delay (seconds) for exponential back-off between retries.
    private let retryBaseDelay: TimeInterval = 1.0

    init() {
        self.callClient = CallClient()
    }

    // MARK: - Create Room

    /// Creates a Daily.co room, retrying up to maxRetries times on failure.
    func createRoom(completion: @escaping (Result<URL, Error>) -> Void) {
        createRoomAttempt(attempt: 0, completion: completion)
    }

    private func createRoomAttempt(attempt: Int, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let apiURL = URL(string: "https://api.daily.co/v1/rooms") else {
            completion(.failure(RoomError.invalidURL))
            return
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(DailyConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "properties": [
                "exp": Int(Date().timeIntervalSince1970) + 3600,
                "enable_chat": true,
                "enable_knocking": false
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                if attempt < self.maxRetries - 1 {
                    let delay = self.retryBaseDelay * pow(2.0, Double(attempt))
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.createRoomAttempt(attempt: attempt + 1, completion: completion)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Room creation failed after \(self.maxRetries) attempts: \(error.localizedDescription)"
                        completion(.failure(error))
                    }
                }
                return
            }

            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let urlString = json["url"] as? String,
                let url = URL(string: urlString)
            else {
                if attempt < self.maxRetries - 1 {
                    let delay = self.retryBaseDelay * pow(2.0, Double(attempt))
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.createRoomAttempt(attempt: attempt + 1, completion: completion)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(RoomError.invalidResponse))
                    }
                }
                return
            }

            DispatchQueue.main.async {
                self.roomURL = url
                completion(.success(url))
            }
        }.resume()
    }

    // MARK: - Join Room

    /// Joins a Daily.co room, retrying up to maxRetries times on failure.
    func joinRoom(url: URL, token: String? = nil) {
        joinRoomAttempt(url: url, token: token, attempt: 0)
    }

    private func joinRoomAttempt(url: URL, token: String?, attempt: Int) {
        callClient.join(url: url, token: token.map { .init($0) }) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.isInRoom = true
                    self.errorMessage = nil
                case .failure(let error):
                    if attempt < self.maxRetries - 1 {
                        let delay = self.retryBaseDelay * pow(2.0, Double(attempt))
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self.joinRoomAttempt(url: url, token: token, attempt: attempt + 1)
                        }
                    } else {
                        self.errorMessage = "Failed to join room after \(self.maxRetries) attempts: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    // MARK: - Leave Room

    func leaveRoom() {
        callClient.leave { [weak self] _ in
            DispatchQueue.main.async {
                self?.isInRoom = false
                self?.roomURL = nil
                self?.roomToken = nil
            }
        }
    }

    // MARK: - Destroy Room

    func destroyRoom(roomName: String) {
        guard let apiURL = URL(string: "https://api.daily.co/v1/rooms/\(roomName)") else { return }
        var request = URLRequest(url: apiURL)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(DailyConfig.apiKey)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }

    // MARK: - Errors

    enum RoomError: LocalizedError {
        case invalidURL
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidURL:      return "Invalid room URL."
            case .invalidResponse: return "Invalid server response from Daily.co API."
            }
        }
    }
}

// MARK: - Daily Config

private enum DailyConfig {
    static let apiKey: String = {
        Bundle.main.infoDictionary?["DAILY_API_KEY"] as? String ?? ""
    }()
}
