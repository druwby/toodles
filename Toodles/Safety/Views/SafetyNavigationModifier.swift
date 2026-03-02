// SafetyNavigationModifier.swift
// Toodles
//
// TDV-53: Integrate contextual safety UX throughout navigation
// Assignee: Danny Shtansky

import SwiftUI

// MARK: - Safety Navigation Modifier

/// A SwiftUI view modifier that injects contextual safety UX into any navigation screen.
///
/// Usage:
/// ```swift
/// VideoCallView()
///     .withSafetyUX(context: .videoCall)
/// ```
///
/// This modifier:
/// - Adds a contextual safety banner below the navigation bar
/// - Adds a shield button to the navigation bar for quick access to the Safety Center
/// - Presents the Safety Sheet and Resources Sheet as needed
struct SafetyNavigationModifier: ViewModifier {

    let context: NavigationContext
    @StateObject private var viewModel: SafetyViewModel

    init(context: NavigationContext) {
        self.context = context
        _viewModel = StateObject(wrappedValue: SafetyViewModel(context: context))
    }

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            // Contextual safety banner (shown when relevant content is available)
            if viewModel.bannerState.isVisible, let item = viewModel.bannerState.item {
                SafetyBannerView(
                    item: item,
                    onDismiss: { viewModel.dismissBanner() },
                    onAction: {
                        if item.type == .emergency || item.type == .resource {
                            viewModel.openResourcesSheet()
                        } else {
                            viewModel.openSafetySheet()
                        }
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.bannerState.isVisible)
            }

            // Main screen content
            content
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.openSafetySheet() }) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.green)
                        .accessibilityLabel("Open Safety Center")
                }
            }
        }
        .sheet(isPresented: $viewModel.showSafetySheet) {
            SafetySheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showResourcesSheet) {
            SafetyResourcesView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.onScreenAppear()
        }
    }
}

// MARK: - View Extension

extension View {
    /// Injects contextual safety UX (banner + shield button) into the current navigation screen.
    /// - Parameter context: The navigation context that determines which safety content to show.
    func withSafetyUX(context: NavigationContext) -> some View {
        modifier(SafetyNavigationModifier(context: context))
    }
}
