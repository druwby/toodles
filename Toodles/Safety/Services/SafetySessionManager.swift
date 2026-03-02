// SafetySessionManager.swift
// Toodles
//
// TDV-53: Integrate contextual safety UX throughout navigation
// Assignee: Danny Shtansky

import Foundation
import Combine

// MARK: - Safety Session Manager

/// Manages the lifecycle of safety content display across the user session.
/// Tracks dismissed items, enforces "show once" logic, and persists state via UserDefaults.
final class SafetySessionManager: ObservableObject {

    static let shared = SafetySessionManager()

    // MARK: - Published State

    @Published private(set) var dismissedItemIDs: Set<UUID> = []
    @Published private(set) var shownOnceItemIDs: Set<UUID> = []

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let dismissedItems   = "safety_dismissed_item_ids"
        static let shownOnceItems   = "safety_shown_once_item_ids"
        static let lastSafetyPrompt = "safety_last_prompt_date"
    }

    // MARK: - Init

    private init() {
        loadPersistedState()
    }

    // MARK: - Public API

    /// Returns whether a safety item should be shown given current session state
    func shouldShow(_ item: SafetyItem) -> Bool {
        if dismissedItemIDs.contains(item.id) { return false }
        if item.showOnce && shownOnceItemIDs.contains(item.id) { return false }
        return true
    }

    /// Marks an item as dismissed (persisted across sessions)
    func dismiss(_ item: SafetyItem) {
        guard item.isDismissible else { return }
        dismissedItemIDs.insert(item.id)
        persistDismissedItems()
    }

    /// Marks an item as having been shown (for show-once logic)
    func markShown(_ item: SafetyItem) {
        if item.showOnce {
            shownOnceItemIDs.insert(item.id)
            persistShownOnceItems()
        }
        UserDefaults.standard.set(Date(), forKey: Keys.lastSafetyPrompt)
    }

    /// Resets all dismissed state (useful for testing or account reset)
    func resetAllDismissed() {
        dismissedItemIDs.removeAll()
        shownOnceItemIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: Keys.dismissedItems)
        UserDefaults.standard.removeObject(forKey: Keys.shownOnceItems)
    }

    /// Returns the date of the last safety prompt shown to the user
    var lastSafetyPromptDate: Date? {
        return UserDefaults.standard.object(forKey: Keys.lastSafetyPrompt) as? Date
    }

    /// Returns true if a safety prompt was shown within the last N hours
    func wasPromptedRecently(withinHours hours: Double = 24.0) -> Bool {
        guard let last = lastSafetyPromptDate else { return false }
        return Date().timeIntervalSince(last) < (hours * 3600)
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        if let data = UserDefaults.standard.data(forKey: Keys.dismissedItems),
           let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            dismissedItemIDs = ids
        }
        if let data = UserDefaults.standard.data(forKey: Keys.shownOnceItems),
           let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            shownOnceItemIDs = ids
        }
    }

    private func persistDismissedItems() {
        if let data = try? JSONEncoder().encode(dismissedItemIDs) {
            UserDefaults.standard.set(data, forKey: Keys.dismissedItems)
        }
    }

    private func persistShownOnceItems() {
        if let data = try? JSONEncoder().encode(shownOnceItemIDs) {
            UserDefaults.standard.set(data, forKey: Keys.shownOnceItems)
        }
    }
}
