import SwiftUI

/// Reusable dark-blue header bar matching the Figma mockups.
///
/// The header extends under the status bar (ignoresSafeArea on the background)
/// while the actual icons/title sit within the safe area.
///
/// Usage:
/// ```
/// VStack(spacing: 0) {
///   ToodlesHeader(title: "Toodles", showCameraIcon: true)
///   // ... screen content
/// }
/// .toolbar(.hidden, for: .navigationBar)
/// ```
struct ToodlesHeader: View {
    let title: String
    var showCameraIcon: Bool = false
    var showBackButton: Bool = false
    var onBack: (() -> Void)? = nil
    /// SF Symbol name for the trailing button. Default is hamburger menu;
    /// pass "ellipsis" for the three-dot chat menu, or nil to hide it.
    var trailingIcon: String? = "line.3.horizontal"
    var onTrailing: (() -> Void)? = nil
    /// Optional center widget (e.g. avatar + name) that replaces the plain text title.
    var centerContent: AnyView? = nil

    var body: some View {
        HStack(spacing: 10) {
            if showBackButton {
                Button { onBack?() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            if showCameraIcon {
                Image(systemName: "video.fill")
                    .font(.body)
                    .foregroundStyle(.white)
            }
            if let centerContent = centerContent {
                centerContent
            } else {
                Text(title)
                    .font(.body.bold())
                    .foregroundStyle(.white)
            }
            Spacer()
            if let trailingIcon = trailingIcon {
                Button { onTrailing?() } label: {
                    Image(systemName: trailingIcon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(ToodlesTheme.headerBlue.ignoresSafeArea(edges: .top))
    }
}
