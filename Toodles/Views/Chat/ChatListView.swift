import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel = MatchesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.blue, .cyan.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                let matchedOnly = viewModel.rows.filter { $0.status == "matched" }
                if matchedOnly.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "message.slash").font(.system(size: 44)).foregroundStyle(.white.opacity(0.6))
                        Text("No chats yet").foregroundStyle(.white).font(.title3.bold())
                        Text("Like a match in the Matches tab to start a conversation.")
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List(matchedOnly) { row in
                        NavigationLink {
                            ChatDetailView(chatId: row.id, otherName: row.otherName)
                        } label: {
                            HStack {
                                Circle().fill(.white.opacity(0.4)).frame(width: 44, height: 44)
                                    .overlay(Text(String(row.otherName.prefix(2)).uppercased()).foregroundStyle(.white))
                                VStack(alignment: .leading) {
                                    Text(row.otherName).foregroundStyle(.white).bold()
                                    Text("Tap to chat").font(.caption).foregroundStyle(.white.opacity(0.7))
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.15))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Chats")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { viewModel.load() }
        }
    }
}
