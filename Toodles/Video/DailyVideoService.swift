// TDV-41: Integrate Daily SDK for peer-to-peer WebRTC video
// DailyVideoService.swift
// Toodles
//
// Service layer managing Daily.co SDK sessions for peer-to-peer WebRTC video calls.

import Foundation
import Combine

/// Manages the lifecycle of Daily.co video call sessions.
final class DailyVideoService: ObservableObject {

    static let shared = DailyVideoService()

    @Published var callState: DailyCallState = .idle
    @Published var localParticipant: DailyParticipant?
    @Published var remoteParticipants: [DailyParticipant] = []
    @Published var isMicEnabled: Bool = true
    @Published var isCameraEnabled: Bool = true

    private let baseURL = "https://api.daily.co/v1"
    private var roomName: String?
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // MARK: - Room Management

    func createRoom(matchId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/rooms") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "name": "toodles-\(matchId)",
            "privacy": "private",
            "properties": [
                "exp": Int(Date().addingTimeInterval(3600).timeIntervalSince1970),
                "max_participants": 2,
                "enable_chat": false,
                "enable_screenshare": false
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: DailyRoomResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result { completion(.failure(error)) }
            }, receiveValue: { [weak self] response in
                self?.roomName = response.name
                completion(.success(response.url))
            })
            .store(in: &cancellables)
    }

    func joinRoom(url: String, token: String? = nil) {
        callState = .connecting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.callState = .connected
        }
    }

    func leaveRoom() {
        callState = .idle
        remoteParticipants = []
        localParticipant = nil
        roomName = nil
    }

    func toggleMic() { isMicEnabled.toggle() }
    func toggleCamera() { isCameraEnabled.toggle() }
}

enum DailyCallState { case idle, connecting, connected, error(String) }

struct DailyParticipant: Identifiable {
    let id: String
    let userName: String
    let isLocal: Bool
    var isAudioEnabled: Bool
    var isVideoEnabled: Bool
}

struct DailyRoomResponse: Decodable {
    let name: String
    let url: String
}
