# TDV-54: Three-Layer System Architecture Design

**Subtask of:** TDV-28 — Establish System Architecture & Backend Infrastructure  
**Assignee:** Danny Shtansky  

## Summary

This subtask covers the design and documentation of the three-layer system architecture for the Toodles iOS application.

## Architecture Layers

### Layer 1: Client Layer (iOS App)
- Built with **SwiftUI** for declarative UI and **Combine** for reactive data binding
- Manages local state, user interface, and video call interface
- Communicates with both the Video Infrastructure and Serverless Logic layers

### Layer 2: Video Infrastructure Layer
- Powered by **Daily.co SDK** (WebRTC-based)
- Handles peer-to-peer video/audio streaming and call lifecycle management
- Operates independently of Firebase to minimize latency

### Layer 3: Serverless Logic Layer
- Built on **Firebase Cloud Functions** (TypeScript/Node.js)
- Handles trust score calculation, matchmaking, user management, and video session orchestration
- **Cloud Firestore** stores user profiles, match records, and session data
- **Firebase Storage** handles media assets

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Daily.co over Agora/Twilio | Superior WebRTC quality, simpler iOS SDK, built-in recording |
| Firebase Functions over custom server | Serverless scaling, zero infrastructure management |
| Firestore over Realtime Database | Better querying for match/session data, offline support |
| Combine over RxSwift | Native Apple framework, no third-party dependency |

## Deliverables
- `docs/ARCHITECTURE.md` — Full architecture documentation (293 lines)
- Architecture diagram with all three layers and data flow
- Technology stack justification
