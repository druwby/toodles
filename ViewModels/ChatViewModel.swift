// ChatViewModel.swift
// Toodles
//
// TDV-44: Build a real-time messaging interface utilizing Firebase Firestore SDK

import Foundation
import Combine

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isFromCurrentUser: Bool
    let timestamp: Date

    init(id: UUID = UUID(), text: String, isFromCurrentUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isFromCurrentUser = isFromCurrentUser
        self.timestamp = timestamp
    }
}

// MARK: - Chat View Model

final class ChatViewModel: ObservableObject {

    @Published private(set) var messages: [ChatMessage] = []
    @Published var inputText: String = ""

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Intent

    /// Loads messages for the current chat session.
    /// TODO (TDV-44): Replace stub with Firestore real-time listener:
    ///   db.collection("chats").document(chatID)
    ///     .collection("messages").order(by: "timestamp")
    ///     .addSnapshotListener { ... }
    func loadMessages() {
        // Stub: show a welcome placeholder message
        messages = [
            ChatMessage(
                text: "You matched! Say hello 👋",
                isFromCurrentUser: false
            )
        ]
    }

    /// Sends a new message.
    /// TODO (TDV-44): Replace local append with Firestore write:
    ///   db.collection("chats").document(chatID)
    ///     .collection("messages").addDocument(data: [...])
    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let newMessage = ChatMessage(text: trimmed, isFromCurrentUser: true)
        messages.append(newMessage)
        inputText = ""
    }
}
