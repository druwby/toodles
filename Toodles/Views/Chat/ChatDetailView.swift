import SwiftUI
import FirebaseFirestore

struct ChatMessage: Identifiable {
    let id: String
    let senderId: String
    let text: String
    let sentAt: Date
}

final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    let chatId: String
    private var listener: ListenerRegistration?

    init(chatId: String) { self.chatId = chatId }

    func start() {
        // Demo chats (seeded by MatchesViewModel.demoMatches) are served from a
        // static script rather than Firestore — keeps the presentation self-contained
        // and survives network quirks during the Zoom demo.
        if chatId.hasPrefix("demo_match_") {
            self.messages = Self.demoMessages(for: chatId)
            return
        }

        listener?.remove()
        listener = FirestoreService.shared.listenMessages(chatId: chatId) { [weak self] docs in
            DispatchQueue.main.async {
                self?.messages = docs.compactMap { d in
                    guard let id = d["message_id"] as? String,
                          let sender = d["sender_id"] as? String,
                          let text = d["text"] as? String,
                          let ts = d["sent_at"] as? Timestamp else { return nil }
                    return ChatMessage(id: id, senderId: sender, text: text, sentAt: ts.dateValue())
                }
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func send(text: String, senderId: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }

        // For demo chats, append locally instead of writing to Firestore.
        if chatId.hasPrefix("demo_match_") {
            let msg = ChatMessage(
                id: UUID().uuidString,
                senderId: senderId,
                text: t,
                sentAt: Date()
            )
            DispatchQueue.main.async { self.messages.append(msg) }
            return
        }

        FirestoreService.shared.sendMessage(chatId: chatId, senderId: senderId, text: t)
    }

    /// Pre-scripted message threads for the 4 demo girl matches. `me` is whoever is
    /// currently signed in; `her` is the demo match id so the right-left alignment
    /// in `messageBubble` lines up correctly.
    static func demoMessages(for chatId: String) -> [ChatMessage] {
        let me = AuthManager.shared.currentUID ?? "me"
        let now = Date()
        func at(_ minutesAgo: Double) -> Date {
            now.addingTimeInterval(-minutesAgo * 60)
        }

        switch chatId {
        case "demo_match_emma":
            return [
                ChatMessage(id: "m1", senderId: chatId, text: "Your 60 seconds flew by 😄",              sentAt: at(14)),
                ChatMessage(id: "m2", senderId: me,     text: "Right?? Way less awkward than I expected", sentAt: at(13)),
                ChatMessage(id: "m3", senderId: chatId, text: "What was your bachelor project again? Something about trust scores?", sentAt: at(11)),
                ChatMessage(id: "m4", senderId: me,     text: "Yeah! Capstone demo is tomorrow actually",  sentAt: at(10)),
                ChatMessage(id: "m5", senderId: chatId, text: "No way, good luck 🫶 coffee after?",       sentAt: at(2)),
            ]

        case "demo_match_sophia":
            return [
                ChatMessage(id: "m1", senderId: me,     text: "That was fun — your major is business right?", sentAt: at(118)),
                ChatMessage(id: "m2", senderId: chatId, text: "Yep, management concentration. You mentioned CS?", sentAt: at(115)),
                ChatMessage(id: "m3", senderId: me,     text: "Guilty. Mostly iOS stuff lately",              sentAt: at(112)),
                ChatMessage(id: "m4", senderId: chatId, text: "Would love to hear more over food if you're down", sentAt: at(90)),
            ]

        case "demo_match_olivia":
            return [
                ChatMessage(id: "m1", senderId: chatId, text: "I loved how you explained what you're building",   sentAt: at(355)),
                ChatMessage(id: "m2", senderId: me,     text: "Appreciate it. Your art history stuff sounded sick", sentAt: at(350)),
                ChatMessage(id: "m3", senderId: chatId, text: "There's a gallery night on campus Friday, interested?", sentAt: at(340)),
            ]

        case "demo_match_mia":
            return [
                ChatMessage(id: "m1", senderId: me,     text: "Hey! Thanks for the chat yesterday",          sentAt: at(60 * 22)),
                ChatMessage(id: "m2", senderId: chatId, text: "Same! I'm free next week if you are",         sentAt: at(60 * 21)),
                ChatMessage(id: "m3", senderId: me,     text: "Wednesday works for me",                      sentAt: at(60 * 10)),
            ]

        default:
            return []
        }
    }
}

struct ChatDetailView: View {
    let chatId: String
    let otherName: String
    @StateObject private var viewModel: ChatViewModel
    @State private var draft = ""
    @Environment(\.dismiss) private var dismiss

    init(chatId: String, otherName: String) {
        self.chatId = chatId
        self.otherName = otherName
        _viewModel = StateObject(wrappedValue: ChatViewModel(chatId: chatId))
    }

    var body: some View {
        VStack(spacing: 0) {
            ToodlesHeader(
                title: "",
                showBackButton: true,
                onBack: { dismiss() },
                trailingIcon: "ellipsis",
                centerContent: AnyView(headerCenter)
            )

            ZStack {
                ToodlesTheme.bodyGradient.ignoresSafeArea(edges: .bottom)

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.messages) { msg in
                                messageBubble(msg)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }

                    // Input row
                    HStack(spacing: 10) {
                        TextField("Type a message...", text: $draft)
                            .padding(14)
                            .background(Color.white)
                            .clipShape(Capsule())
                        Button {
                            if let uid = AuthManager.shared.currentUID {
                                viewModel.send(text: draft, senderId: uid)
                                draft = ""
                            } else {
                                // Demo fallback: allow sending even without auth in DEMO_MODE
                                viewModel.send(text: draft, senderId: "me")
                                draft = ""
                            }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(ToodlesTheme.accent)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(ToodlesTheme.bodyBottom)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var headerCenter: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(ToodlesTheme.avatarBlue)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(otherName.prefix(2)).uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(ToodlesTheme.avatarText)
                )
            VStack(alignment: .leading, spacing: 0) {
                Text(otherName)
                    .font(.body.bold())
                    .foregroundStyle(.white)
                Text("Online")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
    }

    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        let myId = AuthManager.shared.currentUID ?? "me"
        let isMe = msg.senderId == myId
        VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
            Text(msg.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(ToodlesTheme.chatBubble)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            Text(timeString(msg.sentAt))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: isMe ? .trailing : .leading)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}
