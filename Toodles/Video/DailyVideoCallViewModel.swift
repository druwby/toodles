import Foundation
import Combine
import Daily

// TDV-69: Implement DailyVideoCallViewModel for call state management
// Manages call state, participant tracking, mute/camera controls, and call duration

@MainActor
final class DailyVideoCallViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var callState: CallState = .idle
    @Published var isMuted: Bool = false
    @Published var isCameraOff: Bool = false
    @Published var remoteParticipants: [CallParticipant] = []
    @Published var callDurationFormatted: String = "00:00"
    @Published var errorMessage: String?
    
    // MARK: - Call State Enum
    enum CallState {
        case idle
        case joining
        case joined
        case leaving
        case error(String)
    }
    
    // MARK: - Private Properties
    private let roomManager: DailyRoomManager
    private var callClient: CallClient?
    private var callStartTime: Date?
    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(roomManager: DailyRoomManager = DailyRoomManager()) {
        self.roomManager = roomManager
    }
    
    // MARK: - Call Lifecycle
    
    /// Join a Daily.co room with the given URL
    func joinCall(roomURL: URL, token: String? = nil) {
        guard callState == .idle else { return }
        callState = .joining
        
        let client = CallClient()
        self.callClient = client
        
        // Observe participant events
        observeCallEvents(client: client)
        
        Task {
            do {
                var settings = ClientSettingsUpdate()
                if let token = token {
                    settings.token = .set(MeetingToken(stringValue: token))
                }
                try await client.join(url: roomURL, settings: settings)
                callState = .joined
                callStartTime = Date()
                startCallTimer()
            } catch {
                callState = .error(error.localizedDescription)
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Leave the current call
    func endCall() {
        guard callState == .joined else { return }
        callState = .leaving
        stopCallTimer()
        
        Task {
            try? await callClient?.leave()
            callClient = nil
            callState = .idle
            remoteParticipants = []
            callDurationFormatted = "00:00"
        }
    }
    
    // MARK: - Media Controls
    
    func toggleMute() {
        isMuted.toggle()
        Task {
            try? await callClient?.setInputsEnabled(
                .init(microphone: .set(!isMuted))
            )
        }
    }
    
    func toggleCamera() {
        isCameraOff.toggle()
        Task {
            try? await callClient?.setInputsEnabled(
                .init(camera: .set(!isCameraOff))
            )
        }
    }
    
    // MARK: - Timer
    
    func startCallTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCallDuration()
            }
    }
    
    func stopCallTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func updateCallDuration() {
        guard let start = callStartTime else { return }
        let elapsed = Int(Date().timeIntervalSince(start))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        callDurationFormatted = String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Event Observation
    
    private func observeCallEvents(client: CallClient) {
        // Observe participant join/leave events
        client.publisher(for: \.participants)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] participants in
                self?.remoteParticipants = participants.remote.map { $0.value }
            }
            .store(in: &cancellables)
    }
}
