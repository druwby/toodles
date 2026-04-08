// DailyVideoCallViewModel.swift
// Toodles
//
// TDV-72: Implement DailyVideoCallViewModel for call state management
// Updated: Added retry logic to joinCall and callFailedWithError delegate
// Parent: TDV-41 - Integrate Daily SDK for peer-to-peer video calling

import Foundation
import Daily
import Combine

/// ViewModel that manages the state and lifecycle of a Daily.co video call.
class DailyVideoCallViewModel: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var isInCall: Bool = false
    @Published var isMicMuted: Bool = false
    @Published var isCameraOff: Bool = false
    @Published var isShowingError: Bool = false
    @Published var errorMessage: String?
    @Published var remoteVideoTrack: VideoTrack?
    @Published var localVideoTrack: VideoTrack?
    @Published var remoteParticipantName: String?

    // MARK: - Private Properties

    private let callClient: CallClient
    private var cancellables = Set<AnyCancellable>()

    /// Maximum number of join/reconnect attempts.
    private let maxRetries = 3
    /// Base delay (seconds) for exponential back-off between retries.
    private let retryBaseDelay: TimeInterval = 1.5

    /// Tracks the current join attempt count for retry logic.
    private var joinAttempt: Int = 0
    /// Stores the last URL and token used to join, enabling auto-reconnect.
    private var lastJoinURL: URL?
    private var lastJoinToken: String?

    private var isCameraFront: Bool = true

    // MARK: - Init

    override init() {
        self.callClient = CallClient()
        super.init()
        self.callClient.delegate = self
    }

    // MARK: - Call Lifecycle

    /// Joins a Daily.co call, retrying up to maxRetries times on failure.
    func joinCall(url: URL, token: String? = nil) {
        lastJoinURL = url
        lastJoinToken = token
        joinAttempt = 0
        attemptJoin(url: url, token: token)
    }

    private func attemptJoin(url: URL, token: String?) {
        let settings = ClientSettingsUpdate(
            inputs: .set(InputSettingsUpdate(
                camera: .set(CameraInputSettingsUpdate(isEnabled: .set(true))),
                microphone: .set(MicrophoneInputSettingsUpdate(isEnabled: .set(true)))
            ))
        )
        callClient.updateInputs(settings.inputs ?? .unchanged)

        callClient.join(url: url, token: token.map { .init($0) }) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.isInCall = true
                    self.isShowingError = false
                    self.errorMessage = nil
                    self.joinAttempt = 0
                case .failure(let error):
                    self.joinAttempt += 1
                    if self.joinAttempt < self.maxRetries {
                        let delay = self.retryBaseDelay * pow(2.0, Double(self.joinAttempt - 1))
                        self.errorMessage = "Join failed (attempt \(self.joinAttempt)/\(self.maxRetries)). Retrying in \(Int(delay))s..."
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self.attemptJoin(url: url, token: token)
                        }
                    } else {
                        self.errorMessage = "Could not join the call after \(self.maxRetries) attempts: \(error.localizedDescription)"
                        self.isShowingError = true
                    }
                }
            }
        }
    }

    func leaveCall() {
        callClient.leave { [weak self] _ in
            DispatchQueue.main.async {
                self?.isInCall = false
                self?.remoteVideoTrack = nil
                self?.localVideoTrack = nil
                self?.remoteParticipantName = nil
                self?.joinAttempt = 0
            }
        }
    }

    // MARK: - Controls

    func toggleMic() {
        isMicMuted.toggle()
        callClient.updateInputs(.set(InputSettingsUpdate(
            microphone: .set(MicrophoneInputSettingsUpdate(isEnabled: .set(!isMicMuted)))
        )))
    }

    func toggleCamera() {
        isCameraOff.toggle()
        callClient.updateInputs(.set(InputSettingsUpdate(
            camera: .set(CameraInputSettingsUpdate(isEnabled: .set(!isCameraOff)))
        )))
    }

    func flipCamera() {
        callClient.updateInputs(.set(InputSettingsUpdate(
            camera: .set(CameraInputSettingsUpdate(
                settings: .set(CameraPublishingSettingsUpdate(
                    facingMode: .set(isCameraFront ? .environment : .user)
                ))
            ))
        )))
        isCameraFront.toggle()
    }
}

// MARK: - CallClientDelegate

extension DailyVideoCallViewModel: CallClientDelegate {

    func callClient(_ callClient: CallClient, participantJoined participant: Participant) {
        DispatchQueue.main.async {
            self.remoteParticipantName = participant.info.userName
            if let videoTrack = participant.media?.camera.track {
                self.remoteVideoTrack = videoTrack
            }
        }
    }

    func callClient(_ callClient: CallClient, participantLeft participant: Participant, withReason reason: ParticipantLeftReason) {
        DispatchQueue.main.async {
            self.remoteVideoTrack = nil
            self.remoteParticipantName = nil
        }
    }

    func callClient(_ callClient: CallClient, localParticipantUpdated participant: Participant) {
        DispatchQueue.main.async {
            if let videoTrack = participant.media?.camera.track {
                self.localVideoTrack = videoTrack
            }
        }
    }

    /// Called by the Daily SDK when the call fails mid-session.
    /// Attempts to automatically reconnect using the last known URL and token.
    func callClient(_ callClient: CallClient, callFailedWithError error: Error) {
        DispatchQueue.main.async {
            self.isInCall = false

            guard let url = self.lastJoinURL, self.joinAttempt < self.maxRetries else {
                self.errorMessage = "Call failed: \(error.localizedDescription)"
                self.isShowingError = true
                return
            }

            self.joinAttempt += 1
            let delay = self.retryBaseDelay * pow(2.0, Double(self.joinAttempt - 1))
            self.errorMessage = "Call dropped. Reconnecting (attempt \(self.joinAttempt)/\(self.maxRetries))..."

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.attemptJoin(url: url, token: self.lastJoinToken)
            }
        }
    }
}
