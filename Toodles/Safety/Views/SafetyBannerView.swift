// SafetyBannerView.swift
// Toodles
//
// TDV-53: Integrate contextual safety UX throughout navigation
// Assignee: Danny Shtansky

import SwiftUI

// MARK: - Safety Banner View

/// An inline contextual safety banner that appears at the top of navigation screens.
/// Displays safety tips, warnings, or resource prompts based on the current context.
struct SafetyBannerView: View {

    let item: SafetyItem
    let onDismiss: (() -> Void)?
    let onAction: (() -> Void)?

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 24, height: 24)
                .padding(.top, 2)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(titleColor)

                Text(item.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let label = item.actionLabel {
                    Button(action: { onAction?() }) {
                        Text(label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(accentColor)
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Dismiss button
            if item.isDismissible {
                Button(action: { onDismiss?() }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.type.rawValue.capitalized): \(item.title). \(item.body)")
    }

    // MARK: - Computed Style Properties

    private var iconName: String {
        switch item.type {
        case .tip:       return "lightbulb.fill"
        case .warning:   return "exclamationmark.triangle.fill"
        case .resource:  return "shield.fill"
        case .emergency: return "sos.circle.fill"
        }
    }

    private var iconColor: Color {
        switch item.type {
        case .tip:       return .blue
        case .warning:   return .orange
        case .resource:  return .green
        case .emergency: return .red
        }
    }

    private var titleColor: Color {
        switch item.type {
        case .emergency: return .red
        default:         return .primary
        }
    }

    private var backgroundColor: Color {
        switch item.type {
        case .tip:       return Color.blue.opacity(0.08)
        case .warning:   return Color.orange.opacity(0.08)
        case .resource:  return Color.green.opacity(0.08)
        case .emergency: return Color.red.opacity(0.08)
        }
    }

    private var borderColor: Color {
        switch item.type {
        case .tip:       return Color.blue.opacity(0.25)
        case .warning:   return Color.orange.opacity(0.25)
        case .resource:  return Color.green.opacity(0.25)
        case .emergency: return Color.red.opacity(0.35)
        }
    }

    private var accentColor: Color {
        switch item.type {
        case .tip:       return .blue
        case .warning:   return .orange
        case .resource:  return .green
        case .emergency: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        SafetyBannerView(
            item: SafetyItem(
                type: .tip,
                context: .videoCall,
                title: "Video Call Safety Tips",
                body: "Make sure your background doesn't reveal your location.",
                actionLabel: "Learn More",
                priority: 1,
                isDismissible: true
            ),
            onDismiss: {},
            onAction: {}
        )

        SafetyBannerView(
            item: SafetyItem(
                type: .warning,
                context: .matching,
                title: "Never Send Money",
                body: "Requests for financial help are a major red flag — report them immediately.",
                priority: 1,
                isDismissible: true
            ),
            onDismiss: {},
            onAction: {}
        )

        SafetyBannerView(
            item: SafetyItem(
                type: .emergency,
                context: .reportUser,
                title: "In Immediate Danger?",
                body: "If you are in immediate danger, please call 911.",
                actionLabel: "View Emergency Resources",
                priority: 1,
                isDismissible: false
            ),
            onDismiss: nil,
            onAction: {}
        )
    }
    .padding(.vertical)
}
