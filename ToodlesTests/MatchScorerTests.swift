// MatchScorerTests.swift
// ToodlesTests
// TDV-81 / Subproject B — see docs/superpowers/specs/2026-04-22-toodles-v1.1-roadmap-design.md
//
// Pure-function tests. No Firestore, no networking.

import XCTest
@testable import Toodles

final class MatchScorerTests: XCTestCase {

    // MARK: - Jaccard

    func testJaccardEmptyReturnsZero() {
        XCTAssertEqual(MatchScorer.interestJaccard([], []), 0)
    }

    func testJaccardPerfectOverlap() {
        XCTAssertEqual(
            MatchScorer.interestJaccard(["coffee", "hiking"], ["hiking", "coffee"]),
            1.0,
            accuracy: 0.001
        )
    }

    func testJaccardPartialOverlap() {
        // {coffee, hiking} ∩ {coffee, film} = {coffee} → |1|
        // {coffee, hiking} ∪ {coffee, film} = {coffee, hiking, film} → |3|
        // Expected: 1/3
        XCTAssertEqual(
            MatchScorer.interestJaccard(["coffee", "hiking"], ["coffee", "film"]),
            1.0 / 3.0,
            accuracy: 0.001
        )
    }

    func testJaccardCaseInsensitive() {
        XCTAssertEqual(
            MatchScorer.interestJaccard(["Coffee", "HIKING"], ["coffee", "hiking"]),
            1.0,
            accuracy: 0.001
        )
    }

    // MARK: - Trust proximity

    func testTrustProximityIdentical() {
        XCTAssertEqual(MatchScorer.trustProximity(80, 80), 1.0, accuracy: 0.001)
    }

    func testTrustProximityMaxDistance() {
        XCTAssertEqual(MatchScorer.trustProximity(0, 100), 0.0, accuracy: 0.001)
    }

    func testTrustProximityMidRange() {
        // |70 - 50| = 20 → 1 - 0.2 = 0.8
        XCTAssertEqual(MatchScorer.trustProximity(70, 50), 0.8, accuracy: 0.001)
    }

    // MARK: - Age proximity

    func testAgeProximitySameBucket() {
        // Both in 61..<181 range
        XCTAssertEqual(MatchScorer.ageProximity(90, 120), 1.0, accuracy: 0.001)
    }

    func testAgeProximityOneBucketApart() {
        // 30 is in 15..<61, 100 is in 61..<181 — one bucket apart → 0.6
        XCTAssertEqual(MatchScorer.ageProximity(30, 100), 0.6, accuracy: 0.001)
    }

    func testAgeProximityMaxDistance() {
        // 5 is bucket 0, 500 is bucket 4 — four apart → 0
        XCTAssertEqual(MatchScorer.ageProximity(5, 500), 0.0, accuracy: 0.001)
    }

    // MARK: - End-to-end score

    func testIdenticalProfileScoresHigh() {
        let a = StubCandidate(interests: ["coffee", "hiking", "film"], trustScore: 80, accountAgeDays: 180)
        let b = StubCandidate(interests: ["coffee", "hiking", "film"], trustScore: 80, accountAgeDays: 180)
        let score = MatchScorer.score(current: a, candidate: b)
        // Perfect on all three → 60 + 25 + 15 = 100
        XCTAssertEqual(score.total, 100.0, accuracy: 0.001)
    }

    func testCompletelyDifferentProfileScoresLow() {
        let a = StubCandidate(interests: ["coffee"], trustScore: 100, accountAgeDays: 10)
        let b = StubCandidate(interests: ["rugby"],  trustScore: 0,   accountAgeDays: 600)
        let score = MatchScorer.score(current: a, candidate: b)
        // Jaccard = 0 → 0 pts
        // Trust = 0 → 0 pts
        // Age: bucket 0 vs 4 = distance 4 → 0 pts
        XCTAssertEqual(score.total, 0.0, accuracy: 0.001)
    }

    func testBreakdownComponentsSumToTotal() {
        let a = StubCandidate(interests: ["coffee", "hiking"], trustScore: 80, accountAgeDays: 90)
        let b = StubCandidate(interests: ["coffee", "film"],   trustScore: 70, accountAgeDays: 120)
        let score = MatchScorer.score(current: a, candidate: b)
        let sum = score.breakdown.values.reduce(0, +)
        XCTAssertEqual(sum, score.total, accuracy: 0.001)
    }

    func testBreakdownContainsAllWeightedComponents() {
        let a = StubCandidate(interests: ["coffee"], trustScore: 80, accountAgeDays: 90)
        let b = StubCandidate(interests: ["coffee"], trustScore: 80, accountAgeDays: 90)
        let score = MatchScorer.score(current: a, candidate: b)
        XCTAssertEqual(Set(score.breakdown.keys), ["interest", "trust", "age"])
    }
}

// Test-only stub so we aren't tied to User's full Firestore-backed shape.
private struct StubCandidate: MatchCandidate {
    let interests: [String]
    let trustScore: Int
    let accountAgeDays: Int
}
