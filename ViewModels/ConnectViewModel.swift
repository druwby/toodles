import Foundation
import Combine

/// ViewModel for ConnectView.
/// Manages the chat state machine using Combine.
/// TODO (TDV-42): Replace simulated delay with real Cloud Functions call for room token.
final class ConnectViewModel: ObservableObject {

    enum ChatState: Equatable {
        case idle
        case searching
        case connected
    }

    @Published private(set) var state: ChatState = .idle

    private var cancellables = Set<AnyCancellable>()

    func startChat() {
        guard state == .idle else { return }
        state = .searching

        // Simulated delay — replace with real matchmaking call (TDV-42)
        Just(())
            .delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.state = .connected
            }
            .store(in: &cancellables)
    }
}
