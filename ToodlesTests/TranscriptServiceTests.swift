// TranscriptServiceTests.swift
// ToodlesTests
// TDV-84 / Subproject E — see docs/superpowers/specs/2026-04-22-toodles-v1.1-roadmap-design.md
//
// Tests for the synthetic transcript generator. The remote endpoint path
// requires URLSession stubbing — out of scope for v1.1.

import XCTest
@testable import Toodles

final class TranscriptServiceTests: XCTestCase {

    func testSyntheticTranscriptIsMarkedSynthetic() {
        let t = TranscriptService.synthetic(
            sessionID: "abc",
            peerName: "Sam",
            userName: "Danny",
            icebreakerText: "What got you into it?"
        )
        XCTAssertTrue(t.isSynthetic)
    }

    func testSyntheticTranscriptHasReasonableTurnCount() {
        let t = TranscriptService.synthetic(
            sessionID: "abc",
            peerName: "Sam",
            userName: "Danny",
            icebreakerText: "What got you into it?"
        )
        // 5-6 turns per the spec — make sure no one silently collapses
        // the template into a monologue.
        XCTAssertGreaterThanOrEqual(t.turns.count, 5)
        XCTAssertLessThanOrEqual(t.turns.count, 8)
    }

    func testSyntheticTranscriptAlternatesSpeakers() {
        let t = TranscriptService.synthetic(
            sessionID: "abc",
            peerName: "Sam",
            userName: "Danny",
            icebreakerText: "What got you into it?"
        )
        // First turn is "you" (user) because the icebreaker went first.
        XCTAssertEqual(t.turns.first?.speaker, .you)
        // And we alternate — no two consecutive turns should have the same
        // speaker, otherwise the transcript reads like a monologue.
        for i in 1 ..< t.turns.count {
            XCTAssertNotEqual(
                t.turns[i].speaker, t.turns[i - 1].speaker,
                "Turn \(i) doesn't alternate"
            )
        }
    }

    func testSyntheticUsesIcebreakerAsFirstTurn() {
        // The first turn is the icebreaker itself — this is what makes the
        // transcript read as continuous with the prompt shown during the
        // call. Missing this would break the demo narrative.
        let prompt = "What's your petty villain origin story?"
        let t = TranscriptService.synthetic(
            sessionID: "abc",
            peerName: "Sam",
            userName: "Danny",
            icebreakerText: prompt
        )
        XCTAssertEqual(t.turns.first?.text, prompt)
    }

    func testSyntheticDeterministicForSameSessionID() {
        let a = TranscriptService.synthetic(
            sessionID: "same-sid",
            peerName: "Sam",
            userName: "Danny",
            icebreakerText: "x"
        )
        let b = TranscriptService.synthetic(
            sessionID: "same-sid",
            peerName: "Sam",
            userName: "Danny",
            icebreakerText: "x"
        )
        XCTAssertEqual(a.turns.map(\.text), b.turns.map(\.text))
    }

    func testSyntheticFallsBackWhenIcebreakerNil() {
        // The first turn gets a generic fallback prompt — we don't want an
        // empty first line if the caller didn't have an icebreaker on hand.
        let t = TranscriptService.synthetic(
            sessionID: "abc",
            peerName: "Sam",
            userName: "Danny",
            icebreakerText: nil
        )
        XCTAssertFalse(t.turns.first?.text.isEmpty ?? true)
    }

    func testTurnOffsetsAreMonotonicallyIncreasing() {
        // Offsets are used downstream for timeline UIs — they must strictly
        // increase, otherwise the visualization reorders turns.
        let t = TranscriptService.synthetic(
            sessionID: "abc",
            peerName: "Sam",
            userName: "Danny",
            icebreakerText: "x"
        )
        for i in 1 ..< t.turns.count {
            XCTAssertGreaterThan(
                t.turns[i].offsetSeconds,
                t.turns[i - 1].offsetSeconds,
                "Offset not monotonic at turn \(i)"
            )
        }
    }
}
