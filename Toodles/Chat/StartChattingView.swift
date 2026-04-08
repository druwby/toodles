// StartChattingView.swift
// Toodles
// TDV-42: Develop "Start Chatting" logic to request a 60-second secure room token

import SwiftUI

struct StartChattingView: View {
    @StateObject private var viewModel = StartChattingViewModel()
    let matchID: String
    var onRoomReady: ((SecureRoomToken) -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "video.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.purple)
            Text("Ready to Chat?")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Tap the button below to get a secure 60-second room token and start your video chat.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            stateView
            Spacer()
        }
        .padding()
        .navigationTitle("Start Chatting")
    }

    @ViewBuilder
    private var stateView: some View {
        switch viewModel.state {
        case .idle:
            Button(action: {
                Task { await viewModel.startChatting(matchID: matchID) }
            }) {
                Label("Start Chatting", systemImage: "video.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        case .requestingToken:
            VStack(spacing: 12) {
                ProgressView()
                Text("Requesting secure token...").foregroundColor(.secondary)
            }
        case .tokenReady(let token):
            VStack(spacing: 16) {
                ZStack {
                    Circle().stroke(Color.purple.opacity(0.3), lineWidth: 8).frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.countdownSeconds) / 60.0)
                        .stroke(Color.purple, lineWidth: 8)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: viewModel.countdownSeconds)
                    Text("\(viewModel.countdownSeconds)").font(.title2).fontWeight(.bold)
                }
                Text("Token ready! Join within \(viewModel.countdownSeconds)s")
                    .font(.subheadline).foregroundColor(.secondary)
                Button(action: { viewModel.joinRoom(); onRoomReady?(token) }) {
                    Label("Join Room Now", systemImage: "arrow.right.circle.fill")
                        .font(.headline).padding().frame(maxWidth: .infinity)
                        .background(Color.green).foregroundColor(.white).cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }
        case .joiningRoom:
            VStack(spacing: 12) { ProgressView(); Text("Joining room...").foregroundColor(.secondary) }
        case .inRoom:
            Text("You are in the room!").foregroundColor(.green).font(.headline)
        case .failed(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red).font(.largeTitle)
                Text(message).foregroundColor(.red).multilineTextAlignment(.center)
                Button("Try Again") { viewModel.reset() }.buttonStyle(.bordered)
            }
        }
    }
}

struct StartChattingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { StartChattingView(matchID: "preview-match-id") }
    }
}
