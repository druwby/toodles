// TDV-38: Create a profile editor for customizations and photos
// InterestsPickerView.swift
// Toodles

import SwiftUI

private let allInterests: [String] = [
    "Hiking", "Photography", "Cooking", "Travel", "Music",
    "Reading", "Gaming", "Fitness", "Art", "Movies",
    "Coffee", "Dogs", "Cats", "Yoga", "Dancing",
    "Sports", "Tech", "Fashion", "Food", "Outdoors"
]

struct InterestsPickerView: View {
    @Binding var selectedInterests: Set<String>
    let maxSelections: Int

    private let columns = [GridItem(.adaptive(minimum: 90))]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Interests")
                    .font(.headline)
                Spacer()
                Text("\(selectedInterests.count)/\(maxSelections)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(allInterests, id: \.self) { interest in
                    InterestChip(
                        label: interest,
                        isSelected: selectedInterests.contains(interest)
                    ) {
                        toggleInterest(interest)
                    }
                }
            }
        }
    }

    private func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else if selectedInterests.count < maxSelections {
            selectedInterests.insert(interest)
        }
    }
}

// MARK: - Interest Chip
private struct InterestChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    InterestsPickerView(selectedInterests: .constant(["Hiking", "Music"]), maxSelections: 5)
        .padding()
}
