// LanguageFilterView.swift
// Toodles
// TDV-49: Integrate automated text-based language filtering - UI overlay

import SwiftUI

struct LanguageFilterWarningView: View {
    let message: String
    let isBlocked: Bool
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isBlocked ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isBlocked ? .red : .orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(isBlocked ? "Message Blocked" : "Content Warning")
                    .font(.headline)
                    .foregroundColor(isBlocked ? .red : .orange)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isBlocked ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isBlocked ? Color.red.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct LanguageFilterView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LanguageFilterWarningView(
                message: "Message flagged for review.",
                isBlocked: false,
                onDismiss: {}
            )
            LanguageFilterWarningView(
                message: "Critical language policy violation detected.",
                isBlocked: true,
                onDismiss: {}
            )
        }
        .padding()
    }
}
