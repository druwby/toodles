// PostSessionFeedbackViewModel.swift
// Toodles
//
// TDV-48: Implement two-way post-session feedback mechanisms (Like/Dislike/Report)

import Foundation
import Combine

// MARK: - Feedback Option

enum SessionFeedback: Equatable {
    case like
    case dislike
}

// MARK: - Post Session Feedback View Model

final class PostSessionFeedbackViewModel: ObservableObject {

    @Published private(set) var selectedFeedback: SessionFeedback? = nil
    @Published private(set) var isSubmitting: Bool = false

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Intent

    func selectFeedback(_ feedback: SessionFeedback) {
        // Tapping the same option again deselects it
        if selectedFeedback == feedback {
            selectedFeedback = nil
        } else {
            selectedFeedback = feedback
        }
    }

    /// Submits the feedback for the completed session.
    /// TODO (TDV-48): Replace local print with Firestore write:
    ///   db.collection("sessions").document(sessionID)
    ///     .collection("feedback").document(currentUID)
    ///     .setData(["feedback": feedback, "timestamp": ...])
    /// TODO (TDV-48): If feedback is .like, check if match is mutual and
    ///   create a match document in Firestore for both users.
    func submitFeedback(sessionID: String, matchedUID: String) {
        guard !isSubmitting else { return }
        isSubmitting = true

        let feedbackValue = selectedFeedback == .like ? "like" : "dislike"
        print("[PostSessionFeedbackViewModel] Submitting '\(feedbackValue)' for session \(sessionID) with user \(matchedUID)")

        // Stub: simulate async write
        Just(())
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isSubmitting = false
            }
            .store(in: &cancellables)
    }
}
