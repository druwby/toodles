// SafetySheetView.swift
// Toodles
//
// TDV-53: Integrate contextual safety UX throughout navigation
// Assignee: Danny Shtansky

import SwiftUI

// MARK: - Safety Sheet View

/// A full-screen sheet presenting all safety tips for the current navigation context,
/// along with quick access to safety resources and reporting tools.
struct SafetySheetView: View {

    @ObservedObject var viewModel: SafetyViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    safetyHeader

                    // Contextual Tips
                    if !viewModel.availableItems.isEmpty {
                        sectionHeader("Safety Tips for This Screen")
                        ForEach(viewModel.availableItems) { item in
                            SafetyBannerView(
                                item: item,
                                onDismiss: { viewModel.dismissBanner() },
                                onAction: { viewModel.openResourcesSheet() }
                            )
                        }
                    }

                    // Quick Actions
                    sectionHeader("Quick Actions")
                    quickActionsGrid

                    // Emergency Resources
                    sectionHeader("Emergency Resources")
                    ForEach(viewModel.emergencyResources) { resource in
                        SafetyResourceRow(resource: resource)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Safety Center")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Subviews

    private var safetyHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 36))
                    .foregroundColor(.green)
                VStack(alignment: .leading) {
                    Text("Your Safety Matters")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Toodles is committed to keeping you safe.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.08))
            .cornerRadius(14)
            .padding(.horizontal, 16)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.horizontal, 16)
            .padding(.top, 4)
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickActionCard(
                icon: "flag.fill",
                label: "Report a User",
                color: .orange
            ) {
                // Navigate to report flow
            }
            QuickActionCard(
                icon: "nosign",
                label: "Block a User",
                color: .red
            ) {
                // Navigate to block flow
            }
            QuickActionCard(
                icon: "phone.fill",
                label: "Emergency Help",
                color: .red
            ) {
                viewModel.openResourcesSheet()
            }
            QuickActionCard(
                icon: "questionmark.circle.fill",
                label: "Help Center",
                color: .blue
            ) {
                // Navigate to help center
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(color.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Safety Resource Row

struct SafetyResourceRow: View {
    let resource: SafetyResource

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if resource.isEmergency {
                    Image(systemName: "sos.circle.fill")
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
                Text(resource.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Text(resource.description)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                if let phone = resource.phoneNumber {
                    Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: "-", with: ""))")!) {
                        Label(phone, systemImage: "phone.fill")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                if let url = resource.websiteURL {
                    Link(destination: url) {
                        Label("Website", systemImage: "safari.fill")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(14)
        .background(resource.isEmergency ? Color.red.opacity(0.05) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(resource.isEmergency ? Color.red.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    SafetySheetView(
        viewModel: SafetyViewModel(context: .videoCall)
    )
}
