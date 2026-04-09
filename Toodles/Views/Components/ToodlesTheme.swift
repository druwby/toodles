import SwiftUI

/// Shared color + style tokens matching the Figma mockups in Confluence.
enum ToodlesTheme {
    /// Dark navy used for every screen's top header bar.
    static let headerBlue = Color(red: 0.11, green: 0.22, blue: 0.68)

    /// Bright top of the body gradient.
    static let bodyTop = Color(red: 0.25, green: 0.45, blue: 0.92)

    /// Lighter bottom of the body gradient.
    static let bodyBottom = Color(red: 0.42, green: 0.63, blue: 0.99)

    /// Orange used for primary CTAs (Start Chatting, Save Changes, Send message).
    static let accent = Color(red: 0.98, green: 0.58, blue: 0.12)

    /// Light blue for interest chips + chat bubbles.
    static let chipBlue = Color(red: 0.87, green: 0.93, blue: 1.0)

    /// Blue used for avatar backgrounds in white cards.
    static let avatarBlue = Color(red: 0.78, green: 0.87, blue: 1.0)

    /// The dark blue text used inside avatar circles.
    static let avatarText = Color(red: 0.18, green: 0.32, blue: 0.75)

    /// Body gradient used as the background on every tab.
    static var bodyGradient: LinearGradient {
        LinearGradient(
            colors: [bodyTop, bodyBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// Primary CTA button style used across the app (orange capsule, white bold text).
struct ToodlesPrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 56)
            .padding(.horizontal, fullWidth ? 0 : 40)
            .background(configuration.isPressed ? ToodlesTheme.accent.opacity(0.75) : ToodlesTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}
