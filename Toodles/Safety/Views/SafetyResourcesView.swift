// SafetyResourcesView.swift
// Toodles
//
// TDV-53: Integrate contextual safety UX throughout navigation
// Assignee: Danny Shtansky

import SwiftUI

// MARK: - Safety Resources View

/// Presents all safety resources grouped by category.
/// Accessible from any screen via the safety shield button in the navigation bar.
struct SafetyResourcesView: View {

    @ObservedObject var viewModel: SafetyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: SafetyResourceCategory? = nil

    var body: some View {
        NavigationStack {
            List {
                // Emergency section always at top
                Section {
                    ForEach(viewModel.emergencyResources) { resource in
                        SafetyResourceRow(resource: resource)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    Label("Emergency Resources", systemImage: "sos.circle.fill")
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }

                // Non-emergency resources by category
                ForEach(SafetyResourceCategory.allCases, id: \.self) { category in
                    let resources = viewModel.allResources.filter {
                        !$0.isEmergency && $0.category == category
                    }
                    if !resources.isEmpty {
                        Section {
                            ForEach(resources) { resource in
                                SafetyResourceRow(resource: resource)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                            }
                        } header: {
                            Text(category.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Safety Resources")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Category Display Name Extension

extension SafetyResourceCategory {
    var displayName: String {
        switch self {
        case .crisis:       return "Crisis Support"
        case .harassment:   return "Harassment & Abuse"
        case .mentalHealth: return "Mental Health"
        case .localSupport: return "Local Support"
        case .inApp:        return "In-App Resources"
        }
    }
}

// MARK: - Preview

#Preview {
    SafetyResourcesView(
        viewModel: SafetyViewModel(context: .helpCenter)
    )
}
