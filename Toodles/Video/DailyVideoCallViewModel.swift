// TDV-41: Integrate Daily SDK for peer-to-peer WebRTC video
// DailyVideoCallViewModel.swift
// Toodles
//
// ViewModel coordinating Daily.co video call state for the SwiftUI view layer.

import Foundation
import Combine

final class DailyVideoCallViewModel: ObservableObject {

    @Published var callState: DailyCallState = .idle
    @Published var remoteParticipants: [DailyParticipant] = []
    @Published var isMicEnabled: Bool = true
    @Published var isCameraEnabled: Bool = true

    let matchId: String
    let roomURL: String

    private let videoService: DailyVideoService
    private var cancellables = Set<AnyCancellable>()

    init(matchId: String, roomURL: String, videoService: DailyVideoService = .shared) {
        self.matchId = matchId
        self.roomURL = roomURL
        self.videoService = videoService
        bindService()
    }

    private func bindService() {
        videoService.$callState
            .receive(on: DispatchQueue.main)
            .assign(to: \.callState, on: self)
            .store(in: &cancellables)
        videoService.$remoteParticipants
            .receive(on: DispatchQueue.main)
            .assign(to: \.remoteParticipants, on: self)
            .store(in: &cancellables)
        videoService.$isMicEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isMicEnabled, on: self)
            .store(in: &cancellables)
        videoService.$isCameraEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isCameraEnabled, on: self)
            .store(in: &cancellables)
    }

    func joinCall() { videoService.joinRoom(url: roomURL) }
    func leaveCall() { videoService.leaveRoom() }
    func endCall() { videoService.leaveRoom() }
    func toggleMic() { videoService.toggleMic() }
    func toggleCamera() { videoService.toggleCamera() }

    var statusText: String {
        switch callState {
        case .idle: return "Initializing..."
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    var isConnected: Bool { callState == .connected }
}
