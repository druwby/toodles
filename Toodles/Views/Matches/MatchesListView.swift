import SwiftUI
import FirebaseFirestore

struct MatchRow: Identifiable {
    let id: String
    let otherName: String
    let status: String
    let timestamp: Date
}

final class MatchesViewModel: ObservableObject {
    @Published var rows: [MatchRow] = []
    @Published var isLoading = false

    func load() {
        guard let uid = AuthManager.shared.currentUID else { return }
        isLoading = true
        FirestoreService.shared.matchesForUser(uid: uid) { [weak self] docs in
            DispatchQueue.main.async {
                self?.rows = docs.compactMap { d in
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
                    return MatchRow(id: id, otherName: name, status: status, timestamp: ts)
                }
                self?.isLoading = false
            }
        }
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
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(row.otherName.prefix(2)).uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(ToodlesTheme.avatarText)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(row.otherName)
                    .font(.body.bold())
                    .foregroundStyle(.black)
                Text(timeAgoString(row.timestamp))
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
            HStack(spacing: 14) {
                Image(systemName: "heart")
                    .foregroundStyle(row.status == "matched" ? .green : Color.gray.opacity(0.4))
                Image(systemName: "xmark")
                    .foregroundStyle(row.status == "rejected" ? .red : Color.gray.opacity(0.4))
                Image(systemName: "flag")
                    .foregroundStyle(row.status == "reported" ? .red : Color.gray.opacity(0.4))
            }
            .font(.body)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
