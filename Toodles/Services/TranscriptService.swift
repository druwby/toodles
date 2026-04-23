// TranscriptService.swift
// Toodles
// TDV-84: Post-call transcript (Subproject E of v1.1 roadmap)
//
// Two operating modes:
//   1. Synthetic (Appetize / DEMO_MODE) — generates a plausible 5-6 turn
//      transcript from the session's icebreaker prompt and both names.
//      Marked as a demo artifact; the UI surfaces that honestly.
//   2. Remote (production) — POSTs to a TRANSCRIPT_ENDPOINT env var whose
//      downstream wraps OpenAI Whisper. The shape is ready to wire; no
//      credentials are committed.
//
// The pivot from real-time Apple Speech to post-call Whisper is documented
// in the v1.1 roadmap spec — Appetize's browser simulator doesn't expose
// a live microphone, so real-time on-device transcription can't be demoed
// honestly on the team's current hardware.

import Foundation

struct TranscriptTurn: Identifiable, Codable, Equatable {
    enum Speaker: String, Codable {
        case you
        case peer
    }
    let id: String
    let speaker: Speaker
    let text: String
    /// Offset from session start in seconds. Helps future UI (playback sync,
    /// clip bookmarking) without locking it in now.
    let offsetSeconds: Double
}

struct Transcript: Equatable {
    let sessionID: String
    let turns: [TranscriptTurn]
    /// True when the transcript came from the synthetic generator rather
    /// than a real ASR backend. The UI labels synthetic transcripts so
    /// they're never confused with ground-truth audio.
    let isSynthetic: Bool
}

enum TranscriptServiceError: LocalizedError {
    case endpointNotConfigured
    case network(String)

    var errorDescription: String? {
        switch self {
        case .endpointNotConfigured:
            return "Transcript endpoint isn't configured for this build."
        case .network(let msg):
            return msg
        }
    }
}

enum TranscriptService {

    /// Env var / Info.plist key where a production build would point at a
    /// Cloud Function or direct Whisper proxy. Intentionally not set for
    /// DEMO_MODE — the synthetic path handles everything.
    static let remoteEndpointKey: String = "TRANSCRIPT_ENDPOINT"

    /// Fetch a transcript for the given session. On DEMO_MODE and on any
    /// build where `audioURL` is nil, returns a synthetic transcript. On
    /// production with a real recording, POSTs to the configured endpoint.
    static func transcribe(
        sessionID: String,
        peerName: String,
        userName: String,
        icebreakerText: String?,
        audioURL: URL? = nil
    ) async throws -> Transcript {
        #if DEMO_MODE
        return synthetic(sessionID: sessionID, peerName: peerName, userName: userName, icebreakerText: icebreakerText)
        #else
        if let audioURL = audioURL,
           let endpoint = Bundle.main.infoDictionary?[remoteEndpointKey] as? String,
           !endpoint.isEmpty,
           let url = URL(string: endpoint) {
            return try await postToEndpoint(url: url, sessionID: sessionID, audioURL: audioURL)
        }
        return synthetic(sessionID: sessionID, peerName: peerName, userName: userName, icebreakerText: icebreakerText)
        #endif
    }

    // MARK: - Synthetic generator

    /// Build a plausible 5-6 turn transcript seeded off the icebreaker. The
    /// seed is deterministic (session ID) so the same peer pair sees the
    /// same transcript if they open the feedback view twice.
    static func synthetic(
        sessionID: String,
        peerName: String,
        userName: String,
        icebreakerText: String?
    ) -> Transcript {
        let seed = IcebreakerService.stableHash(sessionID)
        let template = syntheticTemplates[Int(seed % UInt64(syntheticTemplates.count))]

        let prompt = icebreakerText ?? "So — what brought you here?"
        let turns: [TranscriptTurn] = [
            .init(id: "\(sessionID)-0", speaker: .you,  text: prompt,                   offsetSeconds: 1),
            .init(id: "\(sessionID)-1", speaker: .peer, text: template.peerOpening(peerName), offsetSeconds: 6),
            .init(id: "\(sessionID)-2", speaker: .you,  text: template.youFollowup,     offsetSeconds: 14),
            .init(id: "\(sessionID)-3", speaker: .peer, text: template.peerElaboration, offsetSeconds: 22),
            .init(id: "\(sessionID)-4", speaker: .you,  text: template.youReaction(userName), offsetSeconds: 35),
            .init(id: "\(sessionID)-5", speaker: .peer, text: template.peerCloser,      offsetSeconds: 50),
        ]

        return Transcript(sessionID: sessionID, turns: turns, isSynthetic: true)
    }

    // MARK: - Production endpoint

    private static func postToEndpoint(url: URL, sessionID: String, audioURL: URL) async throws -> Transcript {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "sessionID": sessionID,
            "audioURL":  audioURL.absoluteString
        ])

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(RemoteTranscriptPayload.self, from: data)
            return Transcript(
                sessionID: sessionID,
                turns: decoded.turns,
                isSynthetic: false
            )
        } catch let e as TranscriptServiceError {
            throw e
        } catch {
            throw TranscriptServiceError.network(error.localizedDescription)
        }
    }

    private struct RemoteTranscriptPayload: Decodable {
        let turns: [TranscriptTurn]
    }
}

// MARK: - Synthetic template bank

/// A single "vibe" of conversation — each template maps to a different
/// fictional flow so regenerating a transcript doesn't feel canned.
private struct SyntheticTemplate {
    let peerOpeningFactory: (String) -> String
    let youFollowup: String
    let peerElaboration: String
    let youReactionFactory: (String) -> String
    let peerCloser: String

    func peerOpening(_ name: String) -> String  { peerOpeningFactory(name) }
    func youReaction(_ name: String) -> String  { youReactionFactory(name) }
}

private let syntheticTemplates: [SyntheticTemplate] = [
    SyntheticTemplate(
        peerOpeningFactory: { _ in "Honestly? It changes every week. This week I'd say the library — third floor is criminally underrated." },
        youFollowup: "Oh that's fair. I've been camping in the Sci building commons lately but third floor is a vibe.",
        peerElaboration: "Right? The lighting is warmer and there's almost nobody past 4. Great for studying when the first floor is at capacity.",
        youReactionFactory: { _ in "Noted. I'll test it this week — what's your go-to when you need a break from that grind?" },
        peerCloser: "Probably a walk past the arboretum. Free, fifteen minutes, nobody bothers you."
    ),
    SyntheticTemplate(
        peerOpeningFactory: { _ in "So yeah — two summers ago. Started because a friend dragged me and somehow never stopped." },
        youFollowup: "That's how most of the good ones start. What's the hardest part you didn't expect?",
        peerElaboration: "Probably how bad I was at first. Nobody tells you it takes like three months before anything feels natural.",
        youReactionFactory: { _ in "Same experience here, different hobby. What would you tell someone thinking about starting?" },
        peerCloser: "Just start. The research phase is a trap — you'll learn more in one bad session than a week of reading."
    ),
    SyntheticTemplate(
        peerOpeningFactory: { _ in "Okay, hot take — the new Langsdorf looks great but the HVAC fights me every lecture." },
        youFollowup: "Wait you're serious? I thought I was the only one freezing in there.",
        peerElaboration: "No, everybody hates it. I've started wearing a hoodie to morning classes and it's April.",
        youReactionFactory: { _ in "I'm bringing this up in my next eval. What else is on your petty-grievance list?" },
        peerCloser: "Parking structure C after a rainstorm. Iykyk."
    ),
    SyntheticTemplate(
        peerOpeningFactory: { name in "Oh — I'm \(name), by the way. Nice to meet you. This is the first time I've actually tried this app." },
        youFollowup: "Welcome! Honest feedback so far? I'm iterating on it with my capstone team this week.",
        peerElaboration: "The 60-second timer is weirdly freeing. Removes the pressure to sound interesting for twenty minutes.",
        youReactionFactory: { _ in "That's exactly the bet we made. If I added one feature right now, what would it be?" },
        peerCloser: "An optional icebreaker rotation for when the first one doesn't land. Small, would do a lot."
    ),
]
