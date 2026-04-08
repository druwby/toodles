import SwiftUI

struct PostSessionFeedbackView: View {
    let matchName: String
    var onDone: () -> Void
    @State private var isSaving = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .cyan.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Circle().fill(.white.opacity(0.3)).frame(width: 140, height: 140)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .padding(30)
                            .foregroundStyle(.white)
                    )
                Text(matchName)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("How was your chat?")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 24) {
                    feedbackButton(symbol: "hand.thumbsup.fill", color: .green, label: "Like", status: "matched")
                    feedbackButton(symbol: "hand.thumbsdown.fill", color: .gray, label: "Pass", status: "rejected")
                    feedbackButton(symbol: "flag.fill", color: .red, label: "Report", status: "reported")
                }

                if isSaving {
                    ProgressView().tint(.white)
                }

                Spacer()
            }
        }
        .disabled(isSaving)
    }

    private func feedbackButton(symbol: String, color: Color, label: String, status: String) -> some View {
        Button {
            submit(status: status)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: symbol).font(.system(size: 32))
                Text(label).font(.caption.bold())
            }
            .frame(width: 90, height: 90)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func submit(status: String) {
        guard !isSaving, let uid = AuthManager.shared.currentUID else {
            onDone()
            return
        }
        isSaving = true

        // Fake second user ID for the demo match (not a real Firestore user).
        let fakeOtherUid = "demo_\(matchName.replacingOccurrences(of: " ", with: "_"))"

        FirestoreService.shared.createMatch(userA: uid, userB: fakeOtherUid, status: status) { _ in
            if status == "reported" {
                FirestoreService.shared.createSupportTicket(
                    userId: uid,
                    subject: "Report: \(matchName)",
                    description: "User reported from post-session feedback.",
                    category: "report_user"
                ) { _ in
                    DispatchQueue.main.async { onDone() }
                }
            } else {
                DispatchQueue.main.async { onDone() }
            }
        }
    }
}
