import Foundation
import Combine

// TDV-67: Implement DailyVideoService room creation and teardown
// Manages Daily.co room lifecycle: creation, joining, and cleanup

class DailyRoomManager: ObservableObject {
    
    private let baseURL = "https://api.daily.co/v1"
    private var cancellables = Set<AnyCancellable>()
    
    @Published var currentRoom: DailyRoom?
    @Published var isCreatingRoom: Bool = false
    @Published var roomError: Error?
    
    // MARK: - Create a new Daily.co room for a match session
    func createRoom(matchId: String, expiryMinutes: Int = 30) -> AnyPublisher<DailyRoom, Error> {
        return Future<DailyRoom, Error> { [weak self] promise in
            guard let self = self else { return }
            
            self.isCreatingRoom = true
            
            guard let url = URL(string: "\(self.baseURL)/rooms") else {
                promise(.failure(RoomError.invalidURL))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let expiryTime = Int(Date().timeIntervalSince1970) + (expiryMinutes * 60)
            
            let body: [String: Any] = [
                "name": "toodles-\(matchId)",
                "privacy": "private",
                "properties": [
                    "exp": expiryTime,
                    "max_participants": 2,
                    "enable_chat": false,
                    "enable_screenshare": false,
                    "start_video_off": false,
                    "start_audio_off": false
                ]
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async { self?.isCreatingRoom = false }
                if let error = error { promise(.failure(error)); return }
                guard let data = data,
                      let room = try? JSONDecoder().decode(DailyRoom.self, from: data) else {
                    promise(.failure(RoomError.decodingFailed)); return
                }
                DispatchQueue.main.async { self?.currentRoom = room }
                promise(.success(room))
            }.resume()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Delete/teardown a Daily.co room after session ends
    func deleteRoom(roomName: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else { return }
            guard let url = URL(string: "\(self.baseURL)/rooms/\(roomName)") else {
                promise(.failure(RoomError.invalidURL)); return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            URLSession.shared.dataTask(with: request) { _, _, error in
                if let error = error { promise(.failure(error)) }
                else { DispatchQueue.main.async { self.currentRoom = nil }; promise(.success(())) }
            }.resume()
        }
        .eraseToAnyPublisher()
    }
    
    struct DailyRoom: Codable {
        let id: String
        let name: String
        let url: String
        let privacy: String
        let createdAt: String
        enum CodingKeys: String, CodingKey {
            case id, name, url, privacy
            case createdAt = "created_at"
        }
    }
    
    enum RoomError: LocalizedError {
        case invalidURL, decodingFailed
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid Daily.co API URL."
            case .decodingFailed: return "Failed to decode room response."
            }
        }
    }
}
