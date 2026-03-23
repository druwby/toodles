import Foundation
import Daily

// TDV-70: Implement DailyRoomManager for room creation and teardown
// Parent: TDV-41 - Integrate Daily SDK for peer-to-peer video calling

/// Manages the lifecycle of Daily.co video rooms including creation, joining, and teardown.
class DailyRoomManager: ObservableObject {

    @Published var isInRoom: Bool = false
    @Published var roomURL: URL?
    @Published var errorMessage: String?

    private let callClient: CallClient
    private var roomToken: String?

    init() {
        self.callClient = CallClient()
    }

    func createRoom(completion: @escaping (Result<URL, Error>) -> Void) {
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
            if let error = error {
                DispatchQueue.main.async { self?.errorMessage = error.localizedDescription; completion(.failure(error)) }
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let urlString = json["url"] as? String,
                  let url = URL(string: urlString) else {
                DispatchQueue.main.async { completion(.failure(RoomError.invalidResponse)) }
                return
            }
            DispatchQueue.main.async { self?.roomURL = url; completion(.success(url)) }
        }.resume()
    }

    func joinRoom(url: URL, token: String? = nil) {
        callClient.join(url: url, token: token.map { .init($0) }) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success: self?.isInRoom = true
                case .failure(let error): self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func leaveRoom() {
        callClient.leave { [weak self] _ in
            DispatchQueue.main.async {
                self?.isInRoom = false
                self?.roomURL = nil
                self?.roomToken = nil
            }
        }
    }

    func destroyRoom(roomName: String) {
        guard let apiURL = URL(string: "https://api.daily.co/v1/rooms/\(roomName)") else { return }
        var request = URLRequest(url: apiURL)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(DailyConfig.apiKey)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }

    enum RoomError: LocalizedError {
        case invalidURL, invalidResponse
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid room URL"
            case .invalidResponse: return "Invalid server response"
            }
        }
    }
}

private enum DailyConfig {
    static let apiKey: String = { Bundle.main.infoDictionary?["DAILY_API_KEY"] as? String ?? "" }()
}
