// PostSessionFeedbackView.swift
// Toodles
//
// TDV-48: Implement two-way post-session feedback mechanisms (Like/Dislike/Report)

import SwiftUI

struct PostSessionFeedbackView: View {
    let matchName: String

    // TODO: Replace with real values when integrating with group
    let matchedUID: String = "stub-user-id"
    let sessionID: String = "stub-session-id"

    @StateObject private var viewModel = PostSessionFeedbackViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showReportSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    Text("⏱️")
                        .font(.system(size: 56))
                    Text("Time's up!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("How was your chat with \(matchName)?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Like / Dislike buttons
                HStack(spacing: 32) {
                    // Dislike
                    FeedbackButton(
                        icon: "hand.thumbsdown.fill",
                        label: "Pass",
                        color: .gray,
                        isSelected: viewModel.selectedFeedback == .dislike
                    ) {
                        viewModel.selectFeedback(.dislike)
                    }

                    // Like
                    FeedbackButton(
                        icon: "hand.thumbsup.fill",
                        label: "Like",
                        color: .pink,
                        isSelected: viewModel.selectedFeedback == .like
                    ) {
                        viewModel.selectFeedback(.like)
                    }
                }

                // Report option
                Button {
                    showReportSheet = true
                } label: {
                    Label("Report this user", systemImage: "flag.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                Spacer()

                // Submit button
                Button {
                    viewModel.submitFeedback(
                        sessionID: sessionID,
                        matchedUID: matchedUID
                    )
                    dismiss()
                } label: {
                    Text(viewModel.selectedFeedback == nil ? "Skip" : "Submit")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.selectedFeedback == nil ? Color.gray : Color.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
            .navigationTitle("Session Complete")
            .navigationBarTitleDisplayMode(.inline)
            // TDV-53: Contextual safety UX
            .withSafetyUX(context: .postCall)
        }
        // TDV-47: Reuse ReportUserView from TDV-75
        .sheet(isPresented: $showReportSheet) {
            ReportUserView(
                reportedUID: matchedUID,
                reportedName: matchName
            )
        }
    }
}

// MARK: - Feedback Button

struct FeedbackButton: View {
    let icon: String
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : Color(.systemGray5))
                        .frame(width: 72, height: 72)
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundStyle(isSelected ? .white : color)
                }
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? color : .secondary)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    PostSessionFeedbackView(matchName: "Alex")
}
