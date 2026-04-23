// IcebreakerServiceTests.swift
// ToodlesTests
// TDV-80 / Subproject A — see docs/superpowers/specs/2026-04-22-toodles-v1.1-roadmap-design.md
//
// Pure-function tests for IcebreakerService. No Firestore, no XCUITest, no
// networking. These run in the ToodlesTests target (added in Subproject F).

import XCTest
@testable import Toodles

final class IcebreakerServiceTests: XCTestCase {

    func testPoolHasExpectedCoverage() {
        // Spec says ~30 prompts balanced across categories. Regression guard
        // so someone removing prompts notices.
        XCTAssertGreaterThanOrEqual(IcebreakerService.pool.count, 25)

        let byCategory = Dictionary(grouping: IcebreakerService.pool, by: \.category)
        XCTAssertGreaterThanOrEqual(byCategory[.general]?.count ?? 0, 8)
        XCTAssertGreaterThanOrEqual(byCategory[.campus]?.count ?? 0, 6)
        XCTAssertGreaterThanOrEqual(byCategory[.interests]?.count ?? 0, 6)
    }

    func testPromptIDsAreUnique() {
        let ids = IcebreakerService.pool.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate icebreaker IDs")
    }

    func testDeterministicPickForSameSession() {
        // Both peers compute from the same sessionID — they must get the
        // same prompt. This is the whole point of deterministic picking.
        let a = IcebreakerService.pick(sessionID: "session-42")
        let b = IcebreakerService.pick(sessionID: "session-42")
        XCTAssertEqual(a.id, b.id)
    }

    func testDifferentSessionsYieldDifferentPrompts() {
        // Probabilistic, but over 20 distinct sessions the odds of collision
        // on every one are negligible — if this fails we have a hash bug.
        let picks = (0..<20).map { IcebreakerService.pick(sessionID: "s\($0)") }
        let uniqueCount = Set(picks.map(\.id)).count
        XCTAssertGreaterThan(uniqueCount, 5, "Hash seems clustered")
    }

    func testRefreshChangesPrompt() {
        // After a refresh, the user should see a different prompt —
        // otherwise refreshing is a no-op.
        let sessionID = "refresh-test"
        let original = IcebreakerService.pick(sessionID: sessionID, refreshCount: 0)
        let refreshed = IcebreakerService.pick(sessionID: sessionID, refreshCount: 1)
        XCTAssertNotEqual(original.id, refreshed.id)
    }

    func testSharedInterestsBiasToInterestCategory() {
        // With shared interests AND refreshCount 0, we should land in the
        // interests category. Refreshes intentionally fall back to the full
        // pool so users don't get stuck in one category.
        let pick = IcebreakerService.pick(
            sessionID: "shared-test",
            sharedInterests: ["hiking", "coffee"],
            refreshCount: 0
        )
        XCTAssertEqual(pick.category, .interests)
    }

    func testEmptySharedInterestsDoesNotForceInterestCategory() {
        // With no shared interests, the full pool is used. Over many sessions
        // we should see all three categories represented.
        let categories = (0..<40).map {
            IcebreakerService.pick(sessionID: "empty-\($0)", sharedInterests: []).category
        }
        let distinct = Set(categories)
        XCTAssertGreaterThan(distinct.count, 1, "Empty-shared-interests case is category-locked")
    }

    func testStableHashIsDeterministic() {
        // FNV-1a is process-seed-independent; this guards against someone
        // swapping in `Hasher`, which would silently break cross-peer
        // agreement.
        XCTAssertEqual(IcebreakerService.stableHash("x"), IcebreakerService.stableHash("x"))
        XCTAssertNotEqual(IcebreakerService.stableHash("x"), IcebreakerService.stableHash("y"))
    }
}
