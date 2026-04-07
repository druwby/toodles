// MatchmakingView.swift
// Toodles
// TDV-78: Create MatchmakingView and WaitingRoomView with SwiftUI

import SwiftUI

struct MatchmakingView: View {
    @StateObject private var matchmakingService = MatchmakingService()
    @StateObject private var videoCoordinator = VideoSessionCoordinator()
    @State private var showVideoCall = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 32) {
                    headerSection
                    statusSection
                    controlSection
                }
                .padding()
            }
            .navigationDestination(isPresented: $showVideoCall) {
                VideoCallView(coordinator: videoCoordinator)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: { Text(errorMessage) }
        }
        .onChange(of: matchmakingService.status) { _, newStatus in
            handleStatusChange(newStatus)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.wave.2")
                .font(.system(size: 60))
                .foregroundStyle(.purple.gradient)
            Text("Find a Match")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Text("Connect with someone new for a 5-minute video chat")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 16) {
            switch matchmakingService.status {
            case .idle:
                Text("Ready to meet someone new?")
                    .foregroundColor(.gray)
            case .searching:
                WaitingRoomView(estimatedWait: matchmakingService.estimatedWaitTime)
            case .matched(let partnerUID):
                MatchFoundView(partnerUID: partnerUID)
            case .failed(let error):
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var controlSection: some View {
        VStack(spacing: 16) {
            if matchmakingService.isSearching {
                Button(action: { Task { await matchmakingService.cancelSearch() } }) {
                    Label("Cancel Search", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button(action: { Task { await matchmakingService.startSearching() } }) {
                    Label("Find a Match", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private func handleStatusChange(_ status: MatchmakingStatus) {
        if case .matched(let partnerUID) = status {
            Task {
                do {
                    let roomURL = URL(string: "https://toodles.daily.co/\(partnerUID)")!
                    try await videoCoordinator.joinRoom(url: roomURL, matchID: partnerUID)
                    showVideoCall = true
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        } else if case .failed(let error) = status {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct WaitingRoomView: View {
    let estimatedWait: Int
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.purple)
            Text("Searching" + String(repeating: ".", count: dotCount))
                .font(.headline)
                .foregroundColor(.white)
                .onReceive(timer) { _ in dotCount = (dotCount + 1) % 4 }
            if estimatedWait > 0 {
                Text("Estimated wait: ~\(estimatedWait)s")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct MatchFoundView: View {
    let partnerUID: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
            Text("Match Found!")
                .font(.headline)
                .foregroundColor(.white)
            Text("Connecting to your match...")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct VideoCallView: View {
    @ObservedObject var coordinator: VideoSessionCoordinator
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("Call in progress: \(coordinator.formattedDuration)")
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
                Button("End Call") { Task { await coordinator.leaveRoom() } }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding()
        }
    }
}
