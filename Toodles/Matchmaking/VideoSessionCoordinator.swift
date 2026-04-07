// VideoSessionCoordinator.swift
// Toodles
// TDV-77: Build VideoSessionCoordinator with call lifecycle management

import Foundation
import DailyKit
import Combine
import FirebaseFirestore
import FirebaseAuth

enum CallPhase {
    case idle
    case connecting
    case connected
    case disconnecting
    case ended
    case failed(Error)
}

@MainActor
class VideoSessionCoordinator: ObservableObject {
    @Published var callPhase: CallPhase = .idle
    @Published var sessionDuration: TimeInterval = 0
    @Published var isCallActive: Bool = false
    @Published var localParticipant: DailyParticipant?
    @Published var remoteParticipant: DailyParticipant?
    @Published var isMuted: Bool = false
    @Published var isCameraOff: Bool = false
    private let callClient: DailyCall
    private let db = Firestore.firestore()
    private var sessionTimer: Timer?
    private var sessionStartTime: Date?
    private var matchID: String?
    private let maxCallDuration: TimeInterval = 300
    private let sessionsCollection = "video_sessions"
    init() { self.callClient = DailyCall(); callClient.delegate = self }
    func joinRoom(url: URL, matchID: String) async throws {
        self.matchID = matchID; callPhase = .connecting; isCallActive = true
        do {
            try await callClient.join(url: url, token: nil)
            callPhase = .connected; sessionStartTime = Date()
            startSessionTimer(); await logSessionStart(matchID: matchID)
        } catch { callPhase = .failed(error); isCallActive = false; throw error }
    }
    func leaveRoom() async {
        guard isCallActive else { return }
        callPhase = .disconnecting; stopSessionTimer()
        try? await callClient.leave(); callPhase = .ended; isCallActive = false
        if let matchID = matchID { await logSessionEnd(matchID: matchID) }
    }
    func toggleMute() { isMuted.toggle(); callClient.setLocalAudio(enabled: !isMuted) }
    func toggleCamera() { isCameraOff.toggle(); callClient.setLocalVideo(enabled: !isCameraOff) }
    func switchCamera() { callClient.cycleCamera() }
    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.sessionStartTime else { return }
            Task { @MainActor in
                self.sessionDuration = Date().timeIntervalSince(startTime)
                if self.sessionDuration >= self.maxCallDuration { await self.leaveRoom() }
            }
        }
    }
    private func stopSessionTimer() { sessionTimer?.invalidate(); sessionTimer = nil }
    private func logSessionStart(matchID: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let data: [String: Any] = ["matchID": matchID, "initiatorUID": uid, "startedAt": FieldValue.serverTimestamp(), "status": "active"]
        try? await db.collection(sessionsCollection).document(matchID).setData(data)
    }
    private func logSessionEnd(matchID: String) async {
        let data: [String: Any] = ["endedAt": FieldValue.serverTimestamp(), "duration": sessionDuration, "status": "completed"]
        try? await db.collection(sessionsCollection).document(matchID).updateData(data)
    }
    var formattedDuration: String {
        let m = Int(sessionDuration) / 60; let s = Int(sessionDuration) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
extension VideoSessionCoordinator: DailyCallDelegate {
    func dailyCall(_ call: DailyCall, participantJoined participant: DailyParticipant) {
        if participant.isLocal { localParticipant = participant } else { remoteParticipant = participant }
    }
    func dailyCall(_ call: DailyCall, participantLeft participant: DailyParticipant, withReason reason: DailyParticipantLeftReason) {
        if !participant.isLocal { remoteParticipant = nil; Task { await leaveRoom() } }
    }
    func dailyCall(_ call: DailyCall, participantUpdated participant: DailyParticipant) {
        if participant.isLocal { localParticipant = participant } else { remoteParticipant = participant }
    }
    func dailyCall(_ call: DailyCall, callEndedWithError error: Error) {
        callPhase = .failed(error); isCallActive = false; stopSessionTimer()
    }
}
