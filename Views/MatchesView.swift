import SwiftUI

/// Displays previous matches.
/// TODO (TDV-51): Replace placeholder with real Firestore data.
struct MatchesView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Matches Yet",
                systemImage: "heart.slash",
                description: Text("Start chatting to meet someone new!")
            )
            .navigationTitle("Matches")
        }
    }
}

#Preview {
    MatchesView()
}
