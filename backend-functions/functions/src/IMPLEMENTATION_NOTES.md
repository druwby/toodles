# TDV-55: Firebase Cloud Functions Backend Modules

**Subtask of:** TDV-28 — Establish System Architecture & Backend Infrastructure  
**Assignee:** Danny Shtansky  

## Summary

This subtask covers the implementation of all Firebase Cloud Functions backend modules for the Toodles application.

## Modules Implemented

### `index.ts` — Entry Point & API Router
- Initializes Firebase Admin SDK
- Sets up Express.js HTTP server with CORS
- Exports all callable and HTTP Cloud Functions

### `userManagement.ts` — User Lifecycle
- `onUserCreated`: Triggered on new Firebase Auth user — creates Firestore profile, initializes trust score to 50
- `onUserDeleted`: Triggered on user deletion — cleans up Firestore data and storage assets

### `matchmaking.ts` — Match Algorithm
- `findMatches`: Queries compatible users based on preferences, location radius, and trust score threshold
- `createMatch`: Creates a match document and sends push notifications to both users
- Filters out previously seen/rejected users

### `trustScore.ts` — Trust & Safety System
- `calculateTrustScore`: Computes score from verification status, report history, session completion rate, and profile completeness
- `updateTrustScore`: Called after each session to adjust score based on outcome
- Score range: 0–100; users below 30 are flagged for review

### `videoSessions.ts` — Video Session Orchestration
- `createVideoSession`: Creates a Daily.co room via REST API, stores session metadata in Firestore
- `endVideoSession`: Closes the Daily.co room, updates session record, triggers trust score update

## Files
- `backend-functions/functions/src/index.ts`
- `backend-functions/functions/src/userManagement.ts`
- `backend-functions/functions/src/matchmaking.ts`
- `backend-functions/functions/src/trustScore.ts`
- `backend-functions/functions/src/videoSessions.ts`
- `backend-functions/functions/tsconfig.json`
- `backend-functions/functions/package.json`
