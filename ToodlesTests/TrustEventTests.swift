// TrustEventTests.swift
// ToodlesTests
// TDV-83 / Subproject D — see docs/superpowers/specs/2026-04-22-toodles-v1.1-roadmap-design.md
//
// Tests for the TrustEventKind value semantics. Integration-level tests of
// TrustScoreManager.applyEvent and .accumulatedEventDelta live out of band —
// they require the Firestore emulator, which is out of scope for v1.1.

import XCTest
@testable import Toodles

final class TrustEventTests: XCTestCase {

    // MARK: - Delta semantics — regression guards for the scoring model

    func testPositiveSessionIsModestPositive() {
        XCTAssertEqual(TrustEventKind.positiveSessionCompleted.delta, 2)
    }

    func testNeutralSessionIsZero() {
        XCTAssertEqual(TrustEventKind.neutralSessionCompleted.delta, 0)
    }

    func testReportedBySomeoneIsStronglyNegative() {
        // Being reported should hurt meaningfully — it's the strongest
        // single penalty in the model.
        XCTAssertEqual(TrustEventKind.reportedBySomeone.delta, -8)
        XCTAssertLessThan(
            TrustEventKind.reportedBySomeone.delta,
            TrustEventKind.neutralSessionCompleted.delta
        )
    }

    func testAddedInterestsIsModestPositive() {
        // Adding 3+ interests is a behavioral signal with no direct
        // structural bonus, so it flows as an event rather than via
        // the verification/completeness bonuses.
        XCTAssertEqual(TrustEventKind.addedInterests.delta, 3)
    }

    func testAllEventsHaveDisplayNames() {
        for kind in TrustEventKind.allCases {
            XCTAssertFalse(kind.displayName.isEmpty, "\(kind) has no display name")
        }
    }

    func testDecayIsMild() {
        // Weekly decay should be small — one miss shouldn't tank a score.
        XCTAssertEqual(TrustEventKind.weeklyDecay.delta, -1)
        XCTAssertGreaterThan(TrustEventKind.weeklyDecay.delta, -5)
    }

    // MARK: - Encoding round-trip — catches raw-value collisions if someone
    // renames a case without updating the rawValue string.

    func testAllKindsRoundTripThroughRawValue() {
        for kind in TrustEventKind.allCases {
            let raw = kind.rawValue
            let restored = TrustEventKind(rawValue: raw)
            XCTAssertEqual(restored, kind)
        }
    }

    func testRawValuesAreDistinct() {
        let raws = TrustEventKind.allCases.map(\.rawValue)
        XCTAssertEqual(Set(raws).count, raws.count, "Duplicate rawValue strings")
    }

    // MARK: - Recovery task mapping

    func testEachRecoveryTaskHasPositiveReward() {
        for task in RecoveryTask.allCases {
            XCTAssertGreaterThan(task.reward, 0, "\(task) should grant points")
        }
    }

    func testRecoveryTaskEligibility() {
        var user = User.empty
        user.email = "dshtansky0@csu.fullerton.edu"
        user.displayName = "Danny"
        user.bio = "hi"
        user.profilePhotoUrl = "https://example.com/x.png"
        user.interests = ["coffee", "hiking", "film"]

        XCTAssertTrue(RecoveryTask.verifyEmail.isEligible(for: user))
        XCTAssertTrue(RecoveryTask.addInterests.isEligible(for: user))
        XCTAssertTrue(RecoveryTask.completeProfile.isEligible(for: user))
    }

    func testRecoveryTaskNotEligibleWithoutProfile() {
        let user = User.empty
        XCTAssertFalse(RecoveryTask.completeProfile.isEligible(for: user))
        XCTAssertFalse(RecoveryTask.addInterests.isEligible(for: user))
    }
}
