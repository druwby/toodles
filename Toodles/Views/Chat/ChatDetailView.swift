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

    static func demoMessages(for chatId: String) -> [ChatMessage] {
        let me = AuthManager.shared.currentUID ?? "me"
        let now = Date()
        func at(_ minutesAgo: Double) -> Date {
            now.addingTimeInterval(-minutesAgo * 60)
        }

        switch chatId {
        case "demo_match_emma":
            return [
                ChatMessage(id: "m1", senderId: chatId, text: "Your 60 seconds flew by 😄",                                            sentAt: at(14)),
                ChatMessage(id: "m2", senderId: me,     text: "Right?? Way less awkward than I expected",                             sentAt: at(13)),
                ChatMessage(id: "m3", senderId: chatId, text: "What was your bachelor project again? Something about trust scores?", sentAt: at(11)),
                ChatMessage(id: "m4", senderId: me,     text: "Yeah! Capstone demo is tomorrow actually",                             sentAt: at(10)),
                ChatMessage(id: "m5", senderId: chatId, text: "No way, good luck 🫶 coffee after?",                                    sentAt: at(2)),
            ]

        case "demo_match_sophia":
            return [
                ChatMessage(id: "m1", senderId: me,     text: "That was fun — your major is business right?",     sentAt: at(118)),
                ChatMessage(id: "m2", senderId: chatId, text: "Yep, management concentration. You mentioned CS?", sentAt: at(115)),
                ChatMessage(id: "m3", senderId: me,     text: "Guilty. Mostly iOS stuff lately",                  sentAt: at(112)),
                ChatMessage(id: "m4", senderId: chatId, text: "Would love to hear more over food if you're down", sentAt: at(90)),
            ]

        case "demo_match_olivia":
            return [
                ChatMessage(id: "m1", senderId: chatId, text: "I loved how you explained what you're building",       sentAt: at(355)),
                ChatMessage(id: "m2", senderId: me,     text: "Appreciate it. Your art history stuff sounded sick",   sentAt: at(350)),
                ChatMessage(id: "m3", senderId: chatId, text: "There's a gallery night on campus Friday, interested?", sentAt: at(340)),
            ]

        case "demo_match_mia":
            return [
                ChatMessage(id: "m1", senderId: me,     text: "Hey! Thanks for the chat yesterday",  sentAt: at(60 * 22)),
                ChatMessage(id: "m2", senderId: chatId, text: "Same! I'm free next week if you are", sentAt: at(60 * 21)),
                ChatMessage(id: "m3", senderId: me,     text: "Wednesday works for me",              sentAt: at(60 * 10)),
            ]

        default:
            return []
        }
    }
}

struct ChatDetailView: View {
    let chatId: String
    let otherName: String
    let otherPhotoUrl: String?
    let otherSubtitle: String?
    @StateObject private var viewModel: ChatViewModel
    @State private var draft = ""
    @State private var showOptions = false
    @State private var toastMessage: String?
    @Environment(\.dismiss) private var dismiss

    init(
        chatId: String,
        otherName: String,
        otherPhotoUrl: String? = nil,
        otherSubtitle: String? = nil
    ) {
        self.chatId = chatId
        self.otherName = otherName
        self.otherPhotoUrl = otherPhotoUrl
        self.otherSubtitle = otherSubtitle
        _viewModel = StateObject(wrappedValue: ChatViewModel(chatId: chatId))
    }

    var body: some View {
        VStack(spacing: 0) {
            ToodlesHeader(
                title: "",
                showBackButton: true,
                onBack: { dismiss() },
                trailingIcon: "ellipsis",
                onTrailing: { showOptions = true },
                centerContent: AnyView(headerCenter)
            )

            ZStack(alignment: .top) {
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

                    HStack(spacing: 10) {
                        TextField("Type a message...", text: $draft)
                            .foregroundStyle(.black)
                            .tint(.black)
                            .padding(14)
                            .background(Color.white)
                            .clipShape(Capsule())
                        Button {
                            let senderId = AuthManager.shared.currentUID ?? "me"
                            viewModel.send(text: draft, senderId: senderId)
                            draft = ""
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

                if let toast = toastMessage {
                    Text(toast)
                        .font(.callout.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.85))
                        .clipShape(Capsule())
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .sheet(isPresented: $showOptions) {
            optionsSheet
                // Fixed large-fraction detent so the header photo never clips.
                // Medium was cutting off Emma's face in testing.
                .presentationDetents([.fraction(0.78)])
                .presentationDragIndicator(.visible)
        }
    }

    private var headerCenter: some View {
        HStack(spacing: 8) {
            PersonAvatar(name: otherName, photoUrl: otherPhotoUrl, size: 36)
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

    // MARK: - Options sheet (unmatch / report / block, with the person's photo)

    private var optionsSheet: some View {
        VStack(spacing: 14) {
            PersonAvatar(name: otherName, photoUrl: otherPhotoUrl, size: 140)
                .padding(.top, 28)

            Text(otherName)
                .font(.title2.bold())

            if let sub = otherSubtitle {
                Text(sub)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider().padding(.vertical, 8)

            VStack(spacing: 10) {
                sheetAction(icon: "person.crop.circle", title: "View full profile", tint: .primary) {
                    fireToast("Profile view coming soon")
                }
                sheetAction(icon: "heart.slash", title: "Unmatch", tint: .orange) {
                    // Unmatch should actually leave the chat — toast on the way out.
                    fireToast("Unmatched \(otherName)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        dismiss()
                    }
                }
                sheetAction(icon: "flag", title: "Report", tint: .red) {
                    fireToast("Reported — moderation team notified")
                }
                sheetAction(icon: "nosign", title: "Block", tint: .red) {
                    // Block also exits the chat.
                    fireToast("Blocked \(otherName)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 12)

            Button {
                showOptions = false
            } label: {
                Text("Cancel")
                    .font(.body.bold())
                    .foregroundStyle(.primary)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
    }

    private func sheetAction(icon: String, title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
            showOptions = false
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .opacity(0.5)
            }
            .foregroundStyle(tint)
            .font(.body.bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func fireToast(_ text: String) {
        withAnimation(.easeOut(duration: 0.2)) {
            toastMessage = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeIn(duration: 0.25)) {
                toastMessage = nil
            }
        }
    }
}
