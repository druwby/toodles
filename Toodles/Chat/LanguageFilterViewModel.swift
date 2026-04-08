// LanguageFilterViewModel.swift
// Toodles
// TDV-49: Integrate automated text-based language filtering - ViewModel

import Foundation
import Combine

@MainActor
class LanguageFilterViewModel: ObservableObject {
    @Published var pendingMessage: String = ""
    @Published var filterResult: FilterResult? = nil
    @Published var isBlocked: Bool = false
    @Published var warningMessage: String? = nil

    private let filterService: LanguageFilterService

    init(filterService: LanguageFilterService = LanguageFilterService()) {
        self.filterService = filterService
    }

    /// Called before sending a message to evaluate it
    func evaluateBeforeSend(message: String, sessionID: String) async -> Bool {
        let result = await filterService.evaluateAndLog(message: message, sessionID: sessionID)
        filterResult = result
        switch result {
        case .clean:
            warningMessage = nil
            isBlocked = false
            return true
        case .flagged(let reason):
            warningMessage = reason
            isBlocked = false
            return true // Allow but flag
        case .blocked(let reason):
            warningMessage = reason
            isBlocked = true
            return false // Block the message
        }
    }

    func clearWarning() {
        warningMessage = nil
        filterResult = nil
        isBlocked = false
    }
}
