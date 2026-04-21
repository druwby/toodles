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

    /// Only this specific account gets the pre-seeded demo matches/chats. Any
    /// other signed-in account starts with an empty Matches tab and fills it
    /// dynamically as they Like people via the Start Chatting flow.
    private static let demoSeedEmail = "dshtansky2@csu.fullerton.edu"

    private static func shouldSeedDemoMatches() -> Bool {
        (AuthManager.shared.currentEmail ?? "").lowercased() == demoSeedEmail
    }

    /// Access the current user's Show me preference so the demo seed can
    /// respect gender filters. Read directly from UserDefaults cache to avoid
    /// a circular dependency on UserViewModel (ViewModel doesn't have a
    /// singleton; injecting it into the service would be heavier than needed).
    private var currentShowMePreference: ShowMe? {
        guard let uid = AuthManager.shared.currentUID,
              let data = UserDefaults.standard.dictionary(forKey: "toodles_profile_\(uid)"),
              let raw = data["show_me"] as? String
        else { return nil }
        return ShowMe(rawValue: raw)
    }

    func load() {
        guard let uid = AuthManager.shared.currentUID else {
            self.rows = Self.shouldSeedDemoMatches() ? Self.demoMatches() : []
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
                    let rawName: String
                    if other.hasPrefix("demo_") {
                        rawName = other
                            .replacingOccurrences(of: "demo_", with: "")
                            .replacingOccurrences(of: "_", with: " ")
                    } else {
                        rawName = other
                    }
                    let ts = (d["matched_at"] as? Timestamp)?.dateValue() ?? Date()

                    // If the other party is one of our demo peers, enrich the
                    // row with the peer's real photo + subtitle so dynamically
                    // created matches (from Likes in the call) look identical
                    // to the pre-seeded demo matches.
                    let enrichment = DemoPeerPool.all.first { $0.name == rawName }

                    return MatchRow(
                        id: id,
                        otherName: rawName,
                        status: status,
                        timestamp: ts,
                        subtitle: enrichment?.subtitle,
                        photoUrl: enrichment?.photoUrl
                    )
                }

                // Pre-seed demo matches ONLY for the demo account, and only
                // peers that match the current user's Show me preference.
                // Firestore rows come first, then seed. New accounts start
                // with whatever they've dynamically created via Likes.
                if Self.shouldSeedDemoMatches() {
                    let showMe = self.currentShowMePreference
                    self.rows = firestoreRows + Self.demoMatches(filteredBy: showMe)
                } else {
                    self.rows = firestoreRows
                }
                self.isLoading = false
            }
        }
    }

    /// Hand-curated demo matches used in the CPSC 491 capstone presentation.
    /// IDs start with `demo_match_` so `ChatDetailView` can detect them and
    /// serve mock messages without hitting Firestore.
    static func demoMatches(filteredBy showMe: ShowMe? = nil) -> [MatchRow] {
        let all = allDemoMatches()
        guard let showMe = showMe else { return all }
        return all.filter { row in
            guard let peer = DemoPeerPool.all.first(where: { $0.name == row.otherName }) else {
                return true
            }
            return showMe.matches(peer.gender)
        }
    }

    private static func allDemoMatches() -> [MatchRow] {
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

    /// Only show matches the user actually wants to engage with — hide both
    /// Passed (rejected) and Reported rows. A user has no reason to keep
    /// scrolling past people they've explicitly declined.
    private var visibleRows: [MatchRow] {
        viewModel.rows.filter { $0.status != "rejected" && $0.status != "reported" }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ToodlesHeader(title: "Matches", trailingIcon: nil)

                ZStack {
                    AmbientOrbBackground(intensity: .soft)

                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else if visibleRows.isEmpty {
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
                                ForEach(visibleRows) { row in
                                    NavigationLink {
                                        ChatDetailView(
                                            chatId: row.id,
                                            otherName: row.otherName,
                                            otherPhotoUrl: row.photoUrl,
                                            otherSubtitle: row.subtitle
                                        )
                                    } label: {
                                        matchCard(row)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
