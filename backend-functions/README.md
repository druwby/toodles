# Toodles Backend Functions

Firebase Cloud Functions for the Toodles video dating application.

## Overview

This directory contains the serverless backend logic for Toodles, built on Firebase Cloud Functions and Google Cloud Platform.

## Architecture

The backend is organized into the following modules:

### Core Modules

1. **videoSessions.ts** - Video call management
   - Create Daily.co video rooms
   - Generate meeting tokens
   - Manage video session lifecycle
   - Send call notifications

2. **trustScore.ts** - Trust score calculation
   - Calculate comprehensive user trust scores
   - Update scores based on user behavior
   - Track verification status
   - Monitor reports and reviews

3. **matchmaking.ts** - Matchmaking algorithm
   - Find compatible matches
   - Calculate match scores
   - Store and retrieve matches
   - Handle user preferences

4. **userManagement.ts** - User lifecycle
   - Handle user creation
   - Handle user deletion
   - Send welcome emails
   - Anonymize user data

## Setup

### Prerequisites

- Node.js 18 or higher
- Firebase CLI (`npm install -g firebase-tools`)
- Firebase project with Blaze plan (pay-as-you-go)
- Daily.co account and API key

### Installation

```bash
cd functions
npm install
```

### Configuration

Set Firebase configuration:

```bash
firebase functions:config:set daily.api_key="YOUR_DAILY_API_KEY"
```

For local development, create `.runtimeconfig.json`:

```json
{
  "daily": {
    "api_key": "YOUR_DAILY_API_KEY"
  }
}
```

### Local Development

Start the Firebase emulator suite:

```bash
npm run serve
```

This will start:
- Functions emulator on port 5001
- Firestore emulator on port 8080
- Auth emulator on port 9099
- Emulator UI on port 4000

### Building

Compile TypeScript to JavaScript:

```bash
npm run build
```

### Deployment

Deploy all functions:

```bash
npm run deploy
```

Deploy specific function:

```bash
firebase deploy --only functions:createVideoSessionCallable
```

## API Endpoints

### HTTP Endpoints

#### Health Check
```
GET /health
```

Returns server health status.

#### Create Video Session
```
POST /api/video/session
Authorization: Bearer <token>
Content-Type: application/json

{
  "recipientId": "user123"
}
```

#### Find Matches
```
POST /api/matches/find
Authorization: Bearer <token>
```

#### Get Trust Score
```
GET /api/user/:userId/trust-score
Authorization: Bearer <token>
```

### Callable Functions

#### createVideoSessionCallable
Creates a new video session between two users.

**Parameters:**
- `recipientId` (string): ID of the user to call

**Returns:**
- `sessionId` (string): Unique session identifier
- `roomUrl` (string): Daily.co room URL
- `token` (string): Meeting token for caller
- `expiresAt` (Date): Session expiration time

#### endVideoSessionCallable
Ends an active video session.

**Parameters:**
- `sessionId` (string): Session to end

**Returns:**
- `success` (boolean): Operation result

#### calculateTrustScoreCallable
Calculates comprehensive trust score for a user.

**Parameters:**
- `userId` (string, optional): User ID (defaults to caller)

**Returns:**
- `score` (number): Trust score (0-100)
- `completedCalls` (number): Number of completed calls
- `profileCompleteness` (number): Profile completion percentage
- ... (see TrustScoreData interface)

#### findMatchesCallable
Finds potential matches for the calling user.

**Parameters:**
- `limit` (number, optional): Maximum matches to return (default: 10)

**Returns:**
- Array of MatchResult objects

## Triggered Functions

### Authentication Triggers

#### onUserCreatedTrigger
Triggered when a new user signs up.

Actions:
- Creates user document in Firestore
- Initializes trust score
- Sends welcome email

#### onUserDeletedTrigger
Triggered when a user account is deleted.

Actions:
- Deletes user data
- Anonymizes video sessions
- Anonymizes reviews
- Removes matches

### Scheduled Functions

#### dailyMatchmaking
Runs every 24 hours to refresh matches for all users.

#### weeklyTrustScoreUpdate
Runs every Sunday at midnight PST to recalculate trust scores.

## Data Models

### VideoSession
```typescript
{
  sessionId: string;
  initiatorId: string;
  recipientId: string;
  roomUrl: string;
  roomName: string;
  status: 'pending' | 'active' | 'ended';
  createdAt: Timestamp;
  startedAt: Timestamp | null;
  endedAt: Timestamp | null;
  duration: number; // seconds
}
```

### TrustScore
```typescript
{
  userId: string;
  score: number; // 0-100
  completedCalls: number;
  totalCallDuration: number; // seconds
  profileCompleteness: number; // 0-100
  verificationStatus: string;
  reportCount: number;
  positiveReviews: number;
  negativeReviews: number;
  accountAge: number; // days
  updatedAt: Timestamp;
}
```

### Match
```typescript
{
  matchId: string;
  user1Id: string;
  user2Id: string;
  matchScore: number; // 0-100
  status: 'pending' | 'accepted' | 'rejected';
  createdAt: Timestamp;
  mutualMatch: boolean;
}
```

## Security

### Authentication
All callable functions require Firebase Authentication. HTTP endpoints require Bearer token in Authorization header.

### Authorization
- Users can only access their own data
- Trust scores are private
- Match data is only visible to matched users
- Video sessions are only accessible to participants

### Rate Limiting
Consider implementing rate limiting for production:
- Max 10 video sessions per hour per user
- Max 100 match queries per day per user
- Max 5 trust score calculations per day per user

## Monitoring

### Logs
View function logs:

```bash
npm run logs
```

Or in Firebase Console: Functions > Logs

### Metrics
Monitor in Firebase Console:
- Function invocations
- Execution time
- Error rate
- Memory usage

## Testing

### Unit Tests
```bash
npm test
```

### Integration Tests
Use Firebase emulator suite for integration testing.

## Environment Variables

Required configuration:
- `daily.api_key` - Daily.co API key
- `sendgrid.api_key` - SendGrid API key (for emails)

## Troubleshooting

### Common Issues

**Functions not deploying:**
- Check Node.js version (must be 18)
- Verify Firebase project is on Blaze plan
- Check for TypeScript compilation errors

**Daily.co integration failing:**
- Verify API key is set correctly
- Check Daily.co account status
- Review Daily.co API limits

**Firestore permission denied:**
- Check security rules
- Verify user authentication
- Review Firestore indexes

## Cost Optimization

- Use callable functions instead of HTTP when possible
- Implement caching for frequently accessed data
- Use Firestore queries efficiently
- Monitor function execution time
- Set appropriate memory limits

## Future Enhancements

- [ ] Implement ML-based matchmaking
- [ ] Add video recording capability
- [ ] Integrate payment processing
- [ ] Add real-time messaging
- [ ] Implement advanced analytics
- [ ] Add A/B testing framework

## Support

For issues or questions:
- Check Firebase documentation
- Review Daily.co documentation
- Contact team lead: Danny Shtansky

---
**Version:** 1.0.0  
**Last Updated:** February 25, 2026
