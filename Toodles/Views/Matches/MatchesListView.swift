import SwiftUI
import FirebaseFirestore

struct MatchRow: Identifiable {
    let id: String
    let otherName: String
    let status: String
    let timestamp: Date
    /// Optional subtitle line shown under the name (year + major). Populated for demo mocks.
    let subtitle: String?
}

final class MatchesViewModel: ObservableObject {
    @Published var rows: [MatchRow] = []
    @Published var isLoading = false

    func load() {
        guard let uid = AuthManager.shared.currentUID else {
            // No auth yet — show demo mocks so the tab isn't empty during demo rehearsal.
            self.rows = Self.demoMatches()
            return
        }

        isLoading = true
        FirestoreService.shared.matchesForUser(uid: uid) { [weak self] docs in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let firestoreRows: [MatchRow] = docs.compactMap { d in
                    guard let id = d["match_id"] as? String,
                          let a = d["user_a_id"] as? String,
                          let b = d["user_b_id"] as? String,
                          let status = d["status"] as? String else { return nil }
                    let other = a == uid ? b : a
                    let name: String
                    if other.hasPrefix("demo_") {
                        name = other
                            .replacingOccurrences(of: "demo_", with: "")
                            .replacingOccurrences(of: "_", with: " ")
                    } else {
                        name = other
                    }
                    let ts = (d["matched_at"] as? Timestamp)?.dateValue() ?? Date()
                    return MatchRow(id: id, otherName: name, status: status, timestamp: ts, subtitle: nil)
                }

                // Demo seed: always append the mock girls so the Matches + Chats tabs
                // have content during the capstone presentation. The real Firestore rows
                // (if any) show first; demo mocks follow.
                self.rows = firestoreRows + Self.demoMatches()
                self.isLoading = false
            }
        }
    }

    /// Hand-curated demo matches used in the CPSC 491 capstone presentation.
    /// Ordered newest-first. IDs intentionally start with `demo_match_` so
    /// `ChatDetailView` can detect them and serve mock messages without hitting Firestore.
    static func demoMatches() -> [MatchRow] {
        let now = Date()
        return [
            MatchRow(
                id: "demo_match_emma",
                otherName: "Emma Chen",
                status: "matched",
                timestamp: now.addingTimeInterval(-15 * 60),          // 15 min ago
                subtitle: "Junior · Nursing"
            ),
            MatchRow(
                id: "demo_match_sophia",
                otherName: "Sophia Rodriguez",
                status: "matched",
                timestamp: now.addingTimeInterval(-2 * 3600),         // 2 hr ago
                subtitle: "Sophomore · Business"
            ),
            MatchRow(
                id: "demo_match_olivia",
                otherName: "Olivia Kim",
                status: "matched",
                timestamp: now.addingTimeInterval(-6 * 3600),         // 6 hr ago
                subtitle: "Senior · Art History"
            ),
            MatchRow(
                id: "demo_match_mia",
                otherName: "Mia Patel",
                status: "matched",
                timestamp: now.addingTimeInterval(-24 * 3600),        // 1 day ago
                subtitle: "Senior · Biology"
            ),
            MatchRow(
                id: "demo_match_isabella",
                otherName: "Isabella Nguyen",
                status: "rejected",
                timestamp: now.addingTimeInterval(-2 * 24 * 3600),    // 2 days ago
                subtitle: "Junior · Psychology"
            ),
            MatchRow(
                id: "demo_match_ava",
                otherName: "Ava Williams",
                status: "added",
                timestamp: now.addingTimeInterval(-3 * 24 * 3600),    // 3 days ago
                subtitle: "Grad · Data Science"
            ),
        ]
    }
}

struct MatchesListView: View {
    @StateObject private var viewModel = MatchesViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ToodlesHeader(title: "Matches")

            ZStack {
                ToodlesTheme.bodyGradient.ignoresSafeArea(edges: .bottom)

                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else if viewModel.rows.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 44))
                            .foregroundStyle(.white.opacity(0.8))
                        Text("No matches yet")
                            .foregroundStyle(.white)
                            .font(.title3.bold())
                        Text("Tap Start Chatting on the Home tab!")
                            .foregroundStyle(.white.opacity(0.75))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.rows) { row in
                                matchCard(row)
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .onAppear { viewModel.load() }
    }

    private func matchCard(_ row: MatchRow) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(ToodlesTheme.avatarBlue)
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(row.otherName.prefix(2)).uppercased())
                        .font(.subheadline.bold())
                        .foregroundStyle(ToodlesTheme.avatarText)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(row.otherName)
                    .font(.body.bold())
                    .foregroundStyle(.black)
                if let sub = row.subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Text(timeAgoString(row.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.gray.opacity(0.8))
            }
            Spacer()
            statusIcons(for: row.status)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statusIcons(for status: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "heart.fill")
                .foregroundStyle(status == "matched" ? .pink : Color.gray.opacity(0.3))
            Image(systemName: "xmark")
                .foregroundStyle(status == "rejected" ? .red : Color.gray.opacity(0.3))
            Image(systemName: "flag")
                .foregroundStyle(status == "reported" ? .orange : Color.gray.opacity(0.3))
        }
        .font(.body)
    }

    private func timeAgoString(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes) min ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours) hr ago" }
        let days = hours / 24
        return "\(days) day\(days == 1 ? "" : "s") ago"
    }
}
