// StartChattingViewModel.swift
// Toodles
// TDV-42: Develop "Start Chatting" logic to request a 60-second secure room token

import Foundation
import Combine

enum StartChattingState {
    case idle
    case requestingToken
    case tokenReady(SecureRoomToken)
    case joiningRoom
    case inRoom
    case failed(String)
}

@MainActor
class StartChattingViewModel: ObservableObject {
    @Published var state: StartChattingState = .idle
    @Published var countdownSeconds: Int = 60
    @Published var isCountingDown: Bool = false

    private let tokenService: SecureRoomTokenService
    private var countdownTimer: Timer?

    init(tokenService: SecureRoomTokenService = SecureRoomTokenService()) {
        self.tokenService = tokenService
    }

    func startChatting(matchID: String) async {
        state = .requestingToken
        do {
            let token = try await tokenService.requestToken(matchID: matchID)
            state = .tokenReady(token)
            startCountdown(from: 60)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func joinRoom() {
        guard case .tokenReady(let token) = state else { return }
        guard !token.isExpired else {
            state = .failed("Token expired. Please request a new one.")
            stopCountdown()
            return
        }
        stopCountdown()
        state = .joiningRoom
    }

    private func startCountdown(from seconds: Int) {
        countdownSeconds = seconds
        isCountingDown = true
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            Task { @MainActor in
                if self.countdownSeconds > 0 {
                    self.countdownSeconds -= 1
                } else {
                    self.stopCountdown()
                    self.state = .failed("Token expired. Please try again.")
                }
            }
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isCountingDown = false
    }

    func reset() {
        stopCountdown()
        state = .idle
        countdownSeconds = 60
        tokenService.clearToken()
    }

    deinit {
        countdownTimer?.invalidate()
    }
}
