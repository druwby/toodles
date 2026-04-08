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

    init(chatId: String, otherName: String) {
        self.chatId = chatId
        self.otherName = otherName
        _viewModel = StateObject(wrappedValue: ChatViewModel(chatId: chatId))
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .cyan.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.messages) { msg in
                            messageBubble(msg)
                        }
                    }
                    .padding()
                }

                HStack {
                    TextField("Type a message...", text: $draft)
                        .padding(12)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    Button {
                        if let uid = AuthManager.shared.currentUID {
                            viewModel.send(text: draft, senderId: uid)
                            draft = ""
                        }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.orange)
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
        }
        .navigationTitle(otherName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isMe = msg.senderId == AuthManager.shared.currentUID
        HStack {
            if isMe { Spacer() }
            Text(msg.text)
                .padding(12)
                .background(isMe ? Color.orange : Color.white.opacity(0.9))
                .foregroundStyle(isMe ? .white : .black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            if !isMe { Spacer() }
        }
    }
}
