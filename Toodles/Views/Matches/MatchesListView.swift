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
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.blue, .cyan.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else if viewModel.rows.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash").font(.system(size: 44)).foregroundStyle(.white.opacity(0.6))
                        Text("No matches yet").foregroundStyle(.white).font(.title3.bold())
                        Text("Tap Start Chatting on the Home tab!").foregroundStyle(.white.opacity(0.75))
                    }
                } else {
                    List(viewModel.rows) { row in
                        HStack {
                            Circle().fill(.white.opacity(0.4)).frame(width: 44, height: 44)
                                .overlay(Text(String(row.otherName.prefix(2)).uppercased()).foregroundStyle(.white))
                            VStack(alignment: .leading) {
                                Text(row.otherName).font(.body.bold()).foregroundStyle(.white)
                                Text(statusLabel(row.status)).font(.caption).foregroundStyle(.white.opacity(0.75))
                            }
                            Spacer()
                            statusIcon(row.status)
                        }
                        .listRowBackground(Color.white.opacity(0.15))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Matches")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { viewModel.load() }
        }
    }

    private func statusLabel(_ s: String) -> String {
        switch s {
        case "matched": return "Liked"
        case "rejected": return "Passed"
        case "reported": return "Reported"
        default: return s
        }
    }

    @ViewBuilder
    private func statusIcon(_ s: String) -> some View {
        switch s {
        case "matched": Image(systemName: "heart.fill").foregroundStyle(.pink)
        case "rejected": Image(systemName: "xmark").foregroundStyle(.gray)
        case "reported": Image(systemName: "flag.fill").foregroundStyle(.orange)
        default: EmptyView()
        }
    }
}
