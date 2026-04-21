import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var searchQuery = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ToodlesHeader(title: "Chats")

                ZStack {
                    ToodlesTheme.bodyGradient.ignoresSafeArea(edges: .bottom)

                    VStack(spacing: 0) {
                        // Search bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.gray)
                            TextField("Search chats...", text: $searchQuery)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        let matchedOnly = viewModel.rows
                            .filter { $0.status == "matched" }
                            .filter {
                                searchQuery.isEmpty ||
                                $0.otherName.lowercased().contains(searchQuery.lowercased())
                            }

                        if matchedOnly.isEmpty {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "message.slash")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.white.opacity(0.8))
                                Text("No chats yet")
                                    .foregroundStyle(.white)
                                    .font(.title3.bold())
                                Text("Like a match in the Matches tab to start a conversation.")
                                    .foregroundStyle(.white.opacity(0.75))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            Spacer()
                        } else {
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(matchedOnly) { row in
                                        NavigationLink {
                                            ChatDetailView(
                                                chatId: row.id,
                                                otherName: row.otherName,
                                                otherPhotoUrl: row.photoUrl,
                                                otherSubtitle: row.subtitle
                                            )
                                        } label: {
                                            chatCard(row)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear { viewModel.load() }
    }

    private func chatCard(_ row: MatchRow) -> some View {
        HStack(spacing: 12) {
            PersonAvatar(name: row.otherName, photoUrl: row.photoUrl, size: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.otherName)
                    .font(.body.bold())
                    .foregroundStyle(.black)
                if let preview = lastMessagePreview(for: row.id) {
                    Text(preview)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                } else if let sub = row.subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.gray)
                } else {
                    Text("Tap to chat")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            Spacer()
            Text(timeAgoShort(row.timestamp))
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    /// For demo chats, show the last-message text so the list feels like a real
    /// chat index. Falls back to subtitle or "Tap to chat" for non-demo rows.
    private func lastMessagePreview(for chatId: String) -> String? {
        guard chatId.hasPrefix("demo_match_") else { return nil }
        let messages = ChatViewModel.demoMessages(for: chatId)
        return messages.last?.text
    }

    private func timeAgoShort(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        return "\(hours / 24)d"
    }
}
