// HomeViewModel.swift
// Toodles
//
// TDV-50: Build the central hub and Home Screen with "Start Chatting" button

import Foundation
import Combine

final class HomeViewModel: ObservableObject {

    // MARK: - State
    enum ChatState: Equatable {
        case idle
        case searching
        case connected
    }

    @Published private(set) var state: ChatState = .idle

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Intent

    func startChat() {
        guard state == .idle else { return }
        state = .searching

        // TODO (TDV-42): Replace with real Cloud Functions matchmaking call
        // and Daily.co room token handoff
        Just(())
            .delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.state = .connected
            }
            .store(in: &cancellables)
    }

    func cancelSearch() {
        cancellables.removeAll()
        state = .idle
    }
}
