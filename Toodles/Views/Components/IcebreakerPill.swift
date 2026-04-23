// IcebreakerPill.swift
// Toodles
// TDV-80: Icebreaker prompts at session start (Subproject A of v1.1 roadmap)
//
// Glass pill overlay shown at the top of a video call for the first ~12s
// of the session. Tap-to-refresh up to IcebreakerService.maxRefreshes times.

import SwiftUI

struct IcebreakerPill: View {
    let prompt: Icebreaker
    let refreshCount: Int
    let canRefresh: Bool
    var onRefresh: () -> Void

    @State private var isVisible = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "quote.opening")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.75))
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Icebreaker")
                    .font(.caption2.bold())
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.6))
                Text(prompt.text)
                    .font(.callout.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if canRefresh {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.body.bold())
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Try a different icebreaker (\(IcebreakerService.maxRefreshes - refreshCount) left)")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -12)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.black, Color(red: 0.12, green: 0.10, blue: 0.22)],
            startPoint: .top,
            endPoint: .bottom
        ).ignoresSafeArea()

        IcebreakerPill(
            prompt: Icebreaker(id: "c3", category: .campus, text: "Best spot on campus to disappear for an hour?"),
            refreshCount: 1,
            canRefresh: true,
            onRefresh: {}
        )
        .padding()
    }
}
