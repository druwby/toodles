import SwiftUI
import FirebaseFirestore

struct MatchRow: Identifiable {
    let id: String
    let otherName: String
    let status: String
    let timestamp: Date
    /// Optional subtitle line shown under the name (year + major). Populated for demo mocks.
    let subtitle: String?
    /// Optional photo URL. Demo mocks use randomuser.me female portraits;
    /// real Firestore rows fall back to initials in `PersonAvatar` when nil.
    let photoUrl: String?
}

final class MatchesViewModel: ObservableObject {
    @Published var rows: [MatchRow] = []
    @Published var isLoading = false

    func load() {
        guard let uid = AuthManager.shared.currentUID else {
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
                    return MatchRow(
                        id: id,
                        otherName: name,
                        status: status,
                        timestamp: ts,
                        subtitle: nil,
                        photoUrl: nil
                    )
                }

                // Demo seed: always append the mock girls so the Matches + Chats tabs
                // have content during the capstone presentation. Firestore rows appear
                // first; demo mocks follow.
                self.rows = firestoreRows + Self.demoMatches()
                self.isLoading = false
            }
        }
    }

    /// Hand-curated demo matches used in the CPSC 491 capstone presentation.
    /// IDs start with `demo_match_` so `ChatDetailView` can detect them and
    /// serve mock messages without hitting Firestore. Photos are served from
    /// randomuser.me — guaranteed-female portraits, free, deterministic.
    static func demoMatches() -> [MatchRow] {
        let now = Date()
        return [
            MatchRow(
                id: "demo_match_emma",
                otherName: "Emma Chen",
                status: "matched",
                timestamp: now.addingTimeInterval(-15 * 60),
                subtitle: "Junior · Nursing",
                photoUrl: "https://randomuser.me/api/portraits/women/44.jpg"
            ),
            MatchRow(
                id: "demo_match_sophia",
                otherName: "Sophia Rodriguez",
                status: "matched",
                timestamp: now.addingTimeInterval(-2 * 3600),
                subtitle: "Sophomore · Business",
                photoUrl: "https://randomuser.me/api/portraits/women/68.jpg"
            ),
            MatchRow(
                id: "demo_match_olivia",
                otherName: "Olivia Kim",
                status: "matched",
                timestamp: now.addingTimeInterval(-6 * 3600),
                subtitle: "Senior · Art History",
                photoUrl: "https://randomuser.me/api/portraits/women/22.jpg"
            ),
            MatchRow(
                id: "demo_match_mia",
                otherName: "Mia Patel",
                status: "matched",
                timestamp: now.addingTimeInterval(-24 * 3600),
                subtitle: "Senior · Biology",
                photoUrl: "https://randomuser.me/api/portraits/women/90.jpg"
            ),
            MatchRow(
                id: "demo_match_isabella",
                otherName: "Isabella Nguyen",
                status: "rejected",
                timestamp: now.addingTimeInterval(-2 * 24 * 3600),
                subtitle: "Junior · Psychology",
                photoUrl: "https://randomuser.me/api/portraits/women/33.jpg"
            ),
            MatchRow(
                id: "demo_match_ava",
                otherName: "Ava Williams",
                status: "reported",
                timestamp: now.addingTimeInterval(-3 * 24 * 3600),
                subtitle: "Grad · Data Science",
                photoUrl: "https://randomuser.me/api/portraits/women/77.jpg"
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
            PersonAvatar(name: row.otherName, photoUrl: row.photoUrl, size: 54)

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
            statusPill(for: row.status)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    /// Single, unambiguous status pill — replaces the previous icon-row
    /// that could read as empty when a status was "added" or "reported".
    @ViewBuilder
    private func statusPill(for status: String) -> some View {
        switch status {
        case "matched":
            pill(icon: "heart.fill", text: "Matched", fg: .white, bg: Color(red: 0.96, green: 0.35, blue: 0.55))
        case "rejected":
            pill(icon: "xmark", text: "Passed", fg: .white, bg: Color.gray.opacity(0.7))
        case "reported":
            pill(icon: "flag.fill", text: "Reported", fg: .white, bg: Color.red.opacity(0.85))
        case "added":
            pill(icon: "clock.arrow.circlepath", text: "Reconnect", fg: .white, bg: ToodlesTheme.headerBlue)
        default:
            pill(icon: "circle", text: status.capitalized, fg: .white, bg: Color.gray)
        }
    }

    private func pill(icon: String, text: String, fg: Color, bg: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.bold())
            Text(text)
                .font(.caption.bold())
        }
        .foregroundStyle(fg)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(bg)
        .clipShape(Capsule())
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
