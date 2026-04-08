// MatchesListView.swift
// Toodles
// TDV-51: Create a "Matches List" interface displaying previous connections

import SwiftUI

struct MatchEntry: Identifiable {
    let id: String
    let displayName: String
    let profileImageURL: String?
    let lastConnectedAt: Date
    let sessionID: String
    let canReconnect: Bool
}

struct MatchesListView: View {
    @StateObject private var viewModel = MatchesListViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading matches...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.matches.isEmpty {
                    emptyStateView
                } else {
                    matchesList
                }
            }
            .navigationTitle("Matches")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await viewModel.loadMatches() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.loadMatches()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Matches Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Start chatting to make your first connection!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var matchesList: some View {
        List(viewModel.matches) { match in
            MatchRowView(match: match) {
                viewModel.selectMatch(match)
            }
        }
        .listStyle(.plain)
    }
}

struct MatchRowView: View {
    let match: MatchEntry
    let onReconnect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: match.profileImageURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.purple.opacity(0.3))
                    .overlay(Image(systemName: "person.fill").foregroundColor(.purple))
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(match.displayName)
                    .font(.headline)
                Text("Connected \(match.lastConnectedAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if match.canReconnect {
                Button(action: onReconnect) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}

struct MatchesListView_Previews: PreviewProvider {
    static var previews: some View {
        MatchesListView()
    }
}
