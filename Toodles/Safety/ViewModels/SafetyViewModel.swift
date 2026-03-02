// SafetyViewModel.swift
// Toodles
//
// TDV-53: Integrate contextual safety UX throughout navigation
// Assignee: Danny Shtansky

import Foundation
import Combine

// MARK: - Safety View Model

/// Drives the contextual safety UX for a given navigation context.
/// Observes session state and exposes the active safety item to display.
@MainActor
final class SafetyViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var activeSafetyItem: SafetyItem?
    @Published private(set) var bannerState: SafetyBannerState = .hidden
    @Published private(set) var availableItems: [SafetyItem] = []
    @Published var showSafetySheet: Bool = false
    @Published var showResourcesSheet: Bool = false

    // MARK: - Dependencies

    private let context: NavigationContext
    private let provider: SafetyContentProvider
    private let sessionManager: SafetySessionManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        context: NavigationContext,
        provider: SafetyContentProvider = .shared,
        sessionManager: SafetySessionManager = .shared
    ) {
        self.context = context
        self.provider = provider
        self.sessionManager = sessionManager

        setupBindings()
        loadSafetyContent()
    }

    // MARK: - Public Actions

    /// Call when the user enters a screen to trigger contextual safety content
    func onScreenAppear() {
        loadSafetyContent()
        if let item = activeSafetyItem {
            sessionManager.markShown(item)
            bannerState = SafetyBannerState(isVisible: true, item: item, isDismissed: false)
        }
    }

    /// Dismisses the currently visible safety banner
    func dismissBanner() {
        guard let item = bannerState.item else { return }
        sessionManager.dismiss(item)
        bannerState = SafetyBannerState(isVisible: false, item: item, isDismissed: true)
        activeSafetyItem = nil
    }

    /// Opens the full safety information sheet
    func openSafetySheet() {
        showSafetySheet = true
    }

    /// Opens the safety resources sheet (hotlines, external links)
    func openResourcesSheet() {
        showResourcesSheet = true
    }

    /// Returns all safety resources for display in the resources sheet
    var allResources: [SafetyResource] {
        return provider.allResources
    }

    /// Returns emergency-only resources
    var emergencyResources: [SafetyResource] {
        return provider.allResources.filter { $0.isEmergency }
    }

    // MARK: - Private

    private func setupBindings() {
        // Re-evaluate available items when session state changes
        sessionManager.$dismissedItemIDs
            .combineLatest(sessionManager.$shownOnceItemIDs)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.loadSafetyContent()
            }
            .store(in: &cancellables)
    }

    private func loadSafetyContent() {
        let allItems = provider.safetyItems(for: context)
        availableItems = allItems.filter { sessionManager.shouldShow($0) }
        activeSafetyItem = availableItems.first
    }
}
