// IcebreakerService.swift
// Toodles
// TDV-80: Icebreaker prompts at session start (Subproject A of v1.1 roadmap)
//
// Pure, deterministic prompt picker. Both peers in a session pick the same
// prompt because the sessionID is the same on both sides — no server round
// trip needed. Tests live in ToodlesTests/IcebreakerServiceTests.swift.

import Foundation

enum IcebreakerCategory: String, Codable, CaseIterable {
    case general
    case campus
    case interests
}

struct Icebreaker: Identifiable, Hashable, Codable {
    let id: String
    let category: IcebreakerCategory
    let text: String
}

enum IcebreakerService {

    /// Master pool. ~30 prompts balanced across categories. Keep these
    /// CSUF-flavored for campus prompts — the app gates on Fullerton emails,
    /// so landing on a Fullerton reference is a small delight, not a miss.
    static let pool: [Icebreaker] = [
        // General (12)
        .init(id: "g1",  category: .general, text: "What's something you're weirdly good at?"),
        .init(id: "g2",  category: .general, text: "Coffee or tea — and is it a personality trait?"),
        .init(id: "g3",  category: .general, text: "Describe your perfect Sunday in three words."),
        .init(id: "g4",  category: .general, text: "Beach day, hike day, or do-nothing day?"),
        .init(id: "g5",  category: .general, text: "What song is stuck in your head right now?"),
        .init(id: "g6",  category: .general, text: "Morning person or night owl — be honest."),
        .init(id: "g7",  category: .general, text: "Best thing you've watched or read this year?"),
        .init(id: "g8",  category: .general, text: "What's a hobby you've always wanted to try?"),
        .init(id: "g9",  category: .general, text: "Cats, dogs, or something unexpected?"),
        .init(id: "g10", category: .general, text: "Pick one meal forever — go."),
        .init(id: "g11", category: .general, text: "Most useful app on your phone that isn't social media?"),
        .init(id: "g12", category: .general, text: "What's your petty villain origin story?"),

        // Campus (10)
        .init(id: "c1",  category: .campus, text: "Titan Walk or Becker — pick one and defend it."),
        .init(id: "c2",  category: .campus, text: "What class this semester has surprised you the most?"),
        .init(id: "c3",  category: .campus, text: "Best spot on campus to disappear for an hour?"),
        .init(id: "c4",  category: .campus, text: "Most underrated club at CSUF?"),
        .init(id: "c5",  category: .campus, text: "Coffee within walking distance of campus — who wins?"),
        .init(id: "c6",  category: .campus, text: "Dorm, commute, or rent nearby? Which side?"),
        .init(id: "c7",  category: .campus, text: "One thing you'd change about CSUF — go."),
        .init(id: "c8",  category: .campus, text: "Pollak Library floor tier list. Quick."),
        .init(id: "c9",  category: .campus, text: "If you could teach a 1-unit course here, what's it on?"),
        .init(id: "c10", category: .campus, text: "Best weeknight on campus — and what makes it best?"),

        // Interests (8) — intentionally generic so they work for many interest
        // matches. The matchmaker picks these when the two users share at least
        // one interest tag.
        .init(id: "i1", category: .interests, text: "What got you into it in the first place?"),
        .init(id: "i2", category: .interests, text: "Beginner recommendation you'd give?"),
        .init(id: "i3", category: .interests, text: "What's your hot take on it right now?"),
        .init(id: "i4", category: .interests, text: "The thing people sleep on in this space?"),
        .init(id: "i5", category: .interests, text: "Who taught you most about this — person or source?"),
        .init(id: "i6", category: .interests, text: "Last time this made you genuinely excited?"),
        .init(id: "i7", category: .interests, text: "What's the furthest you've taken this?"),
        .init(id: "i8", category: .interests, text: "What's the dumbest barrier to getting started?"),
    ]

    /// Pick a prompt for the given session. Deterministic — both peers compute
    /// the same prompt from the same sessionID. `refreshCount` lets the user
    /// cycle through different prompts if the first one doesn't land.
    ///
    /// When `sharedInterests` is non-empty and `refreshCount` is 0, we weight
    /// toward the `interests` category so the first prompt references common
    /// ground. Refreshes fall back to the full pool.
    static func pick(
        sessionID: String,
        sharedInterests: [String] = [],
        refreshCount: Int = 0
    ) -> Icebreaker {
        let preferInterests = refreshCount == 0 && !sharedInterests.isEmpty
        let candidates = preferInterests
            ? pool.filter { $0.category == .interests }
            : pool

        // Stable hash keyed on sessionID + refreshCount. Can't use Hasher
        // because its seed is randomized per process — the whole point of
        // determinism is that both peers arrive at the same index.
        let seed = "\(sessionID)#\(refreshCount)"
        let hash = stableHash(seed)
        let index = Int(hash % UInt64(candidates.count))
        return candidates[index]
    }

    /// FNV-1a — small, fast, deterministic across runs and across peers.
    static func stableHash(_ s: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in s.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return hash
    }

    /// Max times a user can refresh an icebreaker in a single session. Prevents
    /// infinite spam and keeps the prompt surface as a nudge, not a feature.
    static let maxRefreshes: Int = 3
}
