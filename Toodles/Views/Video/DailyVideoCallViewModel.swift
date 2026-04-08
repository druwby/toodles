// Daily.co SDK integration — preserved for the capstone report narrative.
// Compiled only when DEMO_MODE is NOT set. See MockVideoCallView for
// the active demo video call view-model.
//
// TDV-72: Implement DailyVideoCallViewModel for call state management
// Parent: TDV-41 - Integrate Daily SDK for peer-to-peer video calling

#if !DEMO_MODE
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

    // MARK: - Init
    override init() {
        self.callClient = CallClient()
        super.init()
        self.callClient.delegate = self
    }

    // MARK: - Call Lifecycle

    func joinCall(url: URL, token: String? = nil) {
        let settings = ClientSettingsUpdate(
            inputs: .set(InputSettingsUpdate(
                camera: .set(CameraInputSettingsUpdate(isEnabled: .set(true))),
                microphone: .set(MicrophoneInputSettingsUpdate(isEnabled: .set(true)))
            ))
        )
        callClient.updateInputs(settings.inputs ?? .unchanged)
        callClient.join(url: url, token: token.map { .init($0) }) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.isInCall = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.isShowingError = true
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

    private var isCameraFront: Bool = true
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

    func callClient(_ callClient: CallClient, callFailedWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
            self.isShowingError = true
            self.isInCall = false
        }
    }
}
#endif
