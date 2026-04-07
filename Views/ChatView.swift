// ChatView.swift
// Toodles
//
// TDV-44: Build a real-time messaging interface utilizing Firebase Firestore SDK
// TDV-47: Build in-chat reporting and blocking options

import SwiftUI

struct ChatView: View {
    let matchName: String

    // TODO: Replace with real values when integrating with group
    let reportedUID: String = "stub-user-id"

    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var inputFocused: Bool

    @State private var showReportSheet = false
    @State private var showBlockSheet = false

    var body: some View {
        VStack(spacing: 0) {

            // Message list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: viewModel.messages.count) {
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input bar
            HStack(spacing: 10) {
                TextField("Message…", text: $viewModel.inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($inputFocused)

                Button {
                    viewModel.sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.gray : Color.pink
                        )
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .navigationTitle(matchName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // TDV-47: Report / Block menu
                Menu {
                    Button(role: .destructive) {
                        showReportSheet = true
                    } label: {
                        Label("Report \(matchName)", systemImage: "flag.fill")
                    }

                    Button(role: .destructive) {
                        showBlockSheet = true
                    } label: {
                        Label("Block \(matchName)", systemImage: "nosign")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        // TDV-47: Report sheet — uses ReportUserView from TDV-75
        .sheet(isPresented: $showReportSheet) {
            ReportUserView(
                reportedUID: reportedUID,
                reportedName: matchName
            )
        }
        // TDV-47: Block sheet — uses BlockUserView from TDV-75
        .sheet(isPresented: $showBlockSheet) {
            BlockUserView(
                blockedUID: reportedUID,
                blockedName: matchName
            )
        }
        // TDV-53: Contextual safety UX
        .withSafetyUX(context: .chat)
        .onAppear {
            // TODO (TDV-44): Start Firestore real-time listener here
            viewModel.loadMessages()
        }
        .onDisappear {
            // TODO (TDV-44): Remove Firestore listener here
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isFromCurrentUser { Spacer() }

            Text(message.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isFromCurrentUser ? Color.pink : Color(.systemGray5))
                .foregroundStyle(message.isFromCurrentUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .frame(maxWidth: 280, alignment: message.isFromCurrentUser ? .trailing : .leading)

            if !message.isFromCurrentUser { Spacer() }
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(matchName: "Alex")
    }
}
