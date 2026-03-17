// HomeView.swift
// Toodles
//
// TDV-50: Build the central hub and Home Screen with "Start Chatting" button

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                Spacer()

                // App icon / branding
                VStack(spacing: 12) {
                    Text("👋")
                        .font(.system(size: 64))
                    Text("Toodles")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Meet someone new in 60 seconds.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status area
                Group {
                    switch viewModel.state {
                    case .idle:
                        EmptyView()
                    case .searching:
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("Finding a match…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 16)
                    case .connected:
                        Text("Connected! 🎉")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.bottom, 16)
                    }
                }
                .animation(.easeInOut, value: viewModel.state)

                // Start Chatting button
                Button {
                    viewModel.startChat()
                } label: {
                    Label("Start Chatting", systemImage: "video.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.state == .idle ? Color.pink : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(viewModel.state != .idle)
                .padding(.horizontal, 32)

                // Cancel button shown while searching
                if viewModel.state == .searching {
                    Button("Cancel") {
                        viewModel.cancelSearch()
                    }
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
                }

                Spacer()
                    .frame(height: 48)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            // TDV-53: Attach contextual safety UX
            .withSafetyUX(context: .matching)
        }
    }
}

#Preview {
    HomeView()
}
