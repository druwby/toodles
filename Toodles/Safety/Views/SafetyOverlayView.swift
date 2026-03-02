// SafetyOverlayView.swift
// Toodles
//
// TDV-53: Integrate contextual safety UX throughout navigation
// Assignee: Danny Shtansky

import SwiftUI

// MARK: - Safety Overlay View

/// A floating safety button overlay designed for full-screen contexts like video calls,
/// where the standard navigation bar is hidden. Provides persistent access to safety tools.
struct SafetyOverlayView: View {

    @ObservedObject var viewModel: SafetyViewModel
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                // Floating safety button cluster
                VStack(alignment: .trailing, spacing: 10) {
                    // Expanded action buttons
                    if isExpanded {
                        expandedActions
                            .transition(.scale(scale: 0.8, anchor: .bottomTrailing)
                                .combined(with: .opacity))
                    }

                    // Main shield button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isExpanded.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(isExpanded ? Color.red : Color.green)
                                .frame(width: 52, height: 52)
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)

                            Image(systemName: isExpanded ? "xmark" : "shield.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel(isExpanded ? "Close safety menu" : "Open safety menu")
                }
                .padding(.trailing, 20)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $viewModel.showSafetySheet) {
            SafetySheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showResourcesSheet) {
            SafetyResourcesView(viewModel: viewModel)
        }
    }

    // MARK: - Expanded Actions

    private var expandedActions: some View {
        VStack(alignment: .trailing, spacing: 8) {
            overlayActionButton(
                label: "Safety Tips",
                icon: "lightbulb.fill",
                color: .blue
            ) {
                isExpanded = false
                viewModel.openSafetySheet()
            }

            overlayActionButton(
                label: "Report User",
                icon: "flag.fill",
                color: .orange
            ) {
                isExpanded = false
                // Trigger report flow
            }

            overlayActionButton(
                label: "Emergency Help",
                icon: "sos.circle.fill",
                color: .red
            ) {
                isExpanded = false
                viewModel.openResourcesSheet()
            }
        }
    }

    private func overlayActionButton(
        label: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)

                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Video Call Safety Wrapper

/// Wraps a full-screen video call view with the floating safety overlay.
///
/// Usage:
/// ```swift
/// VideoCallView()
///     .withVideoCallSafetyOverlay()
/// ```
struct VideoCallSafetyModifier: ViewModifier {
    @StateObject private var viewModel = SafetyViewModel(context: .videoCall)

    func body(content: Content) -> some View {
        ZStack(alignment: .bottomTrailing) {
            content
            SafetyOverlayView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.onScreenAppear()
        }
    }
}

extension View {
    /// Adds a floating safety overlay to a full-screen view (e.g., video call screens).
    func withVideoCallSafetyOverlay() -> some View {
        modifier(VideoCallSafetyModifier())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SafetyOverlayView(
            viewModel: SafetyViewModel(context: .videoCall)
        )
    }
}
