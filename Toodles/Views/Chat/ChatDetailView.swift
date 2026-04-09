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
        FirestoreService.shared.sendMessage(chatId: chatId, senderId: senderId, text: t)
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

    // MARK: - Header center (avatar + name + online status)

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

    // MARK: - Message bubble (light blue on both sides per Figma)

    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isMe = msg.senderId == AuthManager.shared.currentUID
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
