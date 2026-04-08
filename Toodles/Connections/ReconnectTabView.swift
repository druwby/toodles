// ReconnectTabView.swift
// Toodles
// TDV-52: Implement a "Reconnect Tab" to continue conversations

import SwiftUI

struct ReconnectTabView: View {
    @StateObject private var viewModel = ReconnectViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading reconnect options...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.reconnectCandidates.isEmpty {
                    emptyStateView
                } else {
                    reconnectList
                }
            }
            .navigationTitle("Reconnect")
            .task {
                await viewModel.loadReconnectCandidates()
            }
            .sheet(item: $viewModel.selectedReconnect) { candidate in
                ReconnectConfirmationView(candidate: candidate) {
                    Task { await viewModel.initiateReconnect(with: candidate) }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.clockwise.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Reconnect Options")
                .font(.title2)
                .fontWeight(.semibold)
            Text("People you've chatted with will appear here so you can continue the conversation.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var reconnectList: some View {
        List(viewModel.reconnectCandidates) { candidate in
            ReconnectCandidateRow(candidate: candidate) {
                viewModel.selectedReconnect = candidate
            }
        }
        .listStyle(.plain)
    }
}

struct ReconnectCandidate: Identifiable {
    let id: String
    let displayName: String
    let profileImageURL: String?
    let lastSessionDate: Date
    let matchID: String
    let mutualInterest: Bool
}

struct ReconnectCandidateRow: View {
    let candidate: ReconnectCandidate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: candidate.profileImageURL ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.orange.opacity(0.3))
                        .overlay(Image(systemName: "person.fill").foregroundColor(.orange))
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(candidate.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        if candidate.mutualInterest {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                                .font(.caption)
                        }
                    }
                    Text("Last chat \(candidate.lastSessionDate, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

struct ReconnectConfirmationView: View {
    let candidate: ReconnectCandidate
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            AsyncImage(url: URL(string: candidate.profileImageURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.orange.opacity(0.3))
                    .overlay(Image(systemName: "person.fill").font(.largeTitle).foregroundColor(.orange))
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())

            Text("Reconnect with \(candidate.displayName)?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Start a new video chat to continue your conversation.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: {
                onConfirm()
                dismiss()
            }) {
                Label("Start Video Chat", systemImage: "video.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)

            Button("Cancel") { dismiss() }
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}

struct ReconnectTabView_Previews: PreviewProvider {
    static var previews: some View {
        ReconnectTabView()
    }
}
