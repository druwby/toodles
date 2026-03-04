# TDV-56: Daily.co Video Session Management and Matchmaking Configuration

**Subtask of:** TDV-28 — Establish System Architecture & Backend Infrastructure  
**Assignee:** Danny Shtansky  

## Daily.co Video Session Configuration

The `videoSessions.ts` module manages the full lifecycle of video calls using the Daily.co REST API.

### Room Creation (`createVideoSession`)

Each video session creates a private Daily.co room with the following configuration:

| Property | Value | Rationale |
|----------|-------|-----------|
| `privacy` | `private` | Prevents unauthorized access; only token holders can join |
| `exp` | `now + 3600s` | Rooms auto-expire after 1 hour to prevent stale sessions |
| `max_participants` | `2` | Enforces 1-on-1 dating session constraint |
| `enable_recording` | `false` | Privacy-first; no recordings without explicit consent |
| `start_video_off` | `false` | Video on by default for dating context |

### Session Metadata (Firestore)

Each session document stored in `videoSessions/{sessionId}` contains:
- `roomUrl`: Daily.co room URL for both participants
- `participantIds`: Array of two user IDs
- `matchId`: Reference to the originating match document
- `createdAt`, `endedAt`: Timestamps for session duration tracking
- `outcome`: User-reported outcome (used for trust score adjustment)

## Matchmaking Algorithm Configuration

The `matchmaking.ts` module implements a preference-based matching system.

### Match Scoring Criteria

Matches are ranked by a composite score calculated from:

| Factor | Weight | Description |
|--------|--------|-------------|
| Age range compatibility | 30% | Both users within each other's stated age preferences |
| Location proximity | 25% | Distance in miles within user's specified radius |
| Trust score | 25% | Both users above minimum threshold (default: 40) |
| Profile completeness | 20% | Higher-quality profiles ranked higher |

### Exclusion Rules
- Users who have previously rejected each other are permanently excluded
- Users with trust score below 30 are excluded from all matches
- Users who have reported each other are excluded
