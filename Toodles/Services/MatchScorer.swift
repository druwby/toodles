// MatchScorer.swift
// Toodles
// TDV-81: Interest-based matching score (Subproject B of v1.1 roadmap)
//
// Pure scoring function. No Firestore, no networking. Tests in
// ToodlesTests/MatchScorerTests.swift.
//
// Components and weights (totals to 100):
//   - Interest Jaccard overlap: 60 pts
//   - Trust-score proximity:    25 pts
//   - Account-age proximity:    15 pts
//
// Report count is intentionally NOT a factor here — it's already baked
// into trustScore via TrustScoreManager, and double-counting it would
// over-penalize peers who ever got a single ambiguous report.

import Foundation

/// Anything that can be scored by MatchScorer. Both `User` (from Models.swift)
/// and `DemoPeer` (from StartChattingView.swift) conform.
protocol MatchCandidate {
    var interests: [String] { get }
    var trustScore: Int { get }
    var accountAgeDays: Int { get }
}

struct MatchScore: Equatable {
    /// Final score on a 0-100 scale. Higher = better match.
    let total: Double
    /// Per-component breakdown. Exposed for tests and debug UI; production
    /// UI should not show these numbers to users.
    let breakdown: [String: Double]

    static let zero = MatchScore(total: 0, breakdown: [:])
}

enum MatchScorer {

    /// Weights sum to 100. Keep the weights here as consts so tweaks are
    /// obvious in a diff.
    private static let wInterest: Double = 60
    private static let wTrust: Double    = 25
    private static let wAge: Double      = 15

    static func score(current: MatchCandidate, candidate: MatchCandidate) -> MatchScore {
        let interestComponent = interestJaccard(current.interests, candidate.interests) * wInterest
        let trustComponent    = trustProximity(current.trustScore, candidate.trustScore) * wTrust
        let ageComponent      = ageProximity(current.accountAgeDays, candidate.accountAgeDays) * wAge

        let total = interestComponent + trustComponent + ageComponent

        return MatchScore(
            total: total,
            breakdown: [
                "interest": interestComponent,
                "trust":    trustComponent,
                "age":      ageComponent,
            ]
        )
    }

    /// Jaccard overlap of two interest sets. Case-insensitive. Returns 0 when
    /// both sets are empty — we don't want to reward two profiles that just
    /// never filled out interests.
    static func interestJaccard(_ a: [String], _ b: [String]) -> Double {
        let setA = Set(a.map { $0.lowercased() })
        let setB = Set(b.map { $0.lowercased() })
        let union = setA.union(setB)
        guard !union.isEmpty else { return 0 }
        let intersection = setA.intersection(setB)
        return Double(intersection.count) / Double(union.count)
    }

    /// Trust-score proximity on [0,1]. Identical scores = 1.0; maximum
    /// distance (0 vs 100) = 0.0. Linear.
    static func trustProximity(_ a: Int, _ b: Int) -> Double {
        let delta = abs(a - b)
        return max(0, 1.0 - Double(delta) / 100.0)
    }

    /// Account-age proximity with a soft-bucket approach — partial credit for
    /// being in "roughly the same cohort" even if not identical. Returns a
    /// value in [0,1].
    ///
    /// Buckets (days): 0-14, 15-60, 61-180, 181-365, 365+. Same bucket = 1.0,
    /// one-bucket-apart = 0.6, two-apart = 0.3, three-apart = 0.1, four+ = 0.
    static func ageProximity(_ a: Int, _ b: Int) -> Double {
        let aBucket = ageBucket(a)
        let bBucket = ageBucket(b)
        let distance = abs(aBucket - bBucket)
        switch distance {
        case 0: return 1.0
        case 1: return 0.6
        case 2: return 0.3
        case 3: return 0.1
        default: return 0
        }
    }

    static func ageBucket(_ days: Int) -> Int {
        switch days {
        case ..<15:    return 0
        case 15..<61:  return 1
        case 61..<181: return 2
        case 181..<366:return 3
        default:       return 4
        }
    }
}

// MARK: - User conformance

extension User: MatchCandidate {
    var accountAgeDays: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
}
