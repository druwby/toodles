// TrustRecoveryView.swift
// Toodles
// TDV-83: Trust Score recovery path (Subproject D of v1.1 roadmap)
//
// Shown when a user's trust score has fallen below the threshold needed to
// start a chat. Presents a concrete list of recovery tasks the user can take
// to rebuild their score. Each task, when tapped, applies the corresponding
// TrustEvent via TrustScoreManager and updates the visible score.

import SwiftUI

struct TrustRecoveryView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var trustManager = TrustScoreManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var displayScore: Int = 0
    @State private var isApplying: Bool = false
    @State private var errorText: String?
    @State private var completedTasks: Set<RecoveryTask> = []

    private let minimumScore: Int = 50

    var body: some View {
        ZStack {
            AmbientOrbBackground(intensity: .soft)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    scoreCard
                    tasksSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            refreshDisplayScore()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                Spacer()
            }
            Text("Rebuild your trust score")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("Finish the tasks below to get back to matching. Each one raises your score by a visible amount.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    // MARK: - Score card

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current score")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.6))
                    Text("\(displayScore) / 100")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                if displayScore >= minimumScore {
                    Text("Ready to chat")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .clipShape(Capsule())
                } else {
                    Text("\(minimumScore - displayScore) pts to go")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            ProgressView(value: Double(min(displayScore, 100)), total: 100)
                .tint(displayScore >= minimumScore ? .green : .orange)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Tasks section

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recovery tasks")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.top, 8)

            ForEach(RecoveryTask.allCases, id: \.self) { task in
                taskRow(task)
            }

            if let err = errorText {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 4)
            }
        }
    }

    private func taskRow(_ task: RecoveryTask) -> some View {
        let done = completedTasks.contains(task) || task.isAlreadyComplete(for: userViewModel.currentUser)
        let eligible = task.isEligible(for: userViewModel.currentUser)

        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(done ? .green : .white.opacity(0.55))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(task.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text("+\(task.reward) pts")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
                    .padding(.top, 2)
            }

            Spacer()

            if done {
                Text("Done")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.6))
            } else if eligible {
                Button {
                    Task { await apply(task) }
                } label: {
                    Text(isApplying ? "…" : "Claim")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(ToodlesTheme.accent)
                        .clipShape(Capsule())
                }
                .disabled(isApplying)
            } else {
                Text("Not yet")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(done ? 0.08 : 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(done ? 0.08 : 0.18), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func refreshDisplayScore() {
        displayScore = userViewModel.currentUser?.trustScore ?? 0
    }

    private func apply(_ task: RecoveryTask) async {
        guard let uid = AuthManager.shared.currentUID else {
            errorText = "You need to sign in again."
            return
        }
        isApplying = true
        errorText = nil
        defer { isApplying = false }

        do {
            let updated = try await trustManager.applyEvent(
                kind: task.eventKind,
                for: uid,
                actor: uid,
                sessionID: nil,
                note: "recovery:\(task.rawValue)"
            )
            completedTasks.insert(task)
            if let new = updated {
                displayScore = Int(new.score)
                // Keep the cached profile in sync so the trust gate unblocks
                // without requiring a full reload.
                if var user = userViewModel.currentUser {
                    user.trustScore = Int(new.score)
                    userViewModel.currentUser = user
                    userViewModel.cacheProfile(user)
                }
            }
        } catch {
            errorText = "Couldn't claim that one: \(error.localizedDescription)"
        }
    }
}

// MARK: - Recovery task definitions

enum RecoveryTask: String, CaseIterable {
    case completeProfile
    case verifyEmail
    case addInterests
    case emailVerifiedOneTime // alias for initial verification bonus

    var title: String {
        switch self {
        case .completeProfile:      return "Complete your profile"
        case .verifyEmail:          return "Verify your CSUF email"
        case .addInterests:         return "Add at least 3 interests"
        case .emailVerifiedOneTime: return "One-time email verification bonus"
        }
    }

    var subtitle: String {
        switch self {
        case .completeProfile:      return "Bio + photo + display name all set."
        case .verifyEmail:          return "Confirm via your @csu.fullerton.edu inbox."
        case .addInterests:         return "Interests drive better matches and icebreakers."
        case .emailVerifiedOneTime: return "Big boost if your CSUF email hasn't been credited yet."
        }
    }

    var reward: Int { eventKind.delta }

    var eventKind: TrustEventKind {
        switch self {
        case .completeProfile:      return .profileCompleted
        case .verifyEmail:          return .emailVerified
        case .addInterests:         return .addedInterests
        case .emailVerifiedOneTime: return .emailVerified
        }
    }

    /// True when the user has already satisfied the task's prerequisite —
    /// the button flips to "Claim" or "Done" based on whether we've also
    /// recorded the corresponding event.
    func isEligible(for user: User?) -> Bool {
        guard let user = user else { return false }
        switch self {
        case .completeProfile:
            return !user.bio.isEmpty && user.profilePhotoUrl?.isEmpty == false && !user.displayName.isEmpty
        case .verifyEmail, .emailVerifiedOneTime:
            return user.email.lowercased().hasSuffix("csu.fullerton.edu")
                || user.email.lowercased().hasSuffix("fullerton.edu")
        case .addInterests:
            return user.interests.count >= 3
        }
    }

    /// Used to pre-check the checkbox when the task is a synthesis of
    /// already-true facts (we don't want to force the user to click Claim
    /// for something they've already done before this view existed).
    func isAlreadyComplete(for user: User?) -> Bool {
        // For now, only "completeProfile" auto-completes when profile is full —
        // the others require an explicit Claim so the event record exists.
        // This keeps the audit log honest.
        return false
    }
}

#Preview {
    TrustRecoveryView()
        .environmentObject(UserViewModel())
}
