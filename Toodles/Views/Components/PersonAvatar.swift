import SwiftUI

/// Circular avatar that shows a loaded photo when `photoUrl` is set, or falls
/// back to initials on a light-blue background. Used in match cards, chat list
/// rows, the chat header, and the chat options sheet so the same avatar style
/// appears everywhere the user sees another person.
struct PersonAvatar: View {
    let name: String
    let photoUrl: String?
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let urlStr = photoUrl,
               !urlStr.isEmpty,
               let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        initialsFallback
                    case .empty:
                        initialsFallback
                    @unknown default:
                        initialsFallback
                    }
                }
            } else {
                initialsFallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsFallback: some View {
        ZStack {
            Circle().fill(ToodlesTheme.avatarBlue)
            Text(String(name.prefix(2)).uppercased())
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(ToodlesTheme.avatarText)
        }
    }
}
