# Toodles - System Architecture Documentation

## Overview
Toodles is a video dating application built with a three-layer architecture to support real-time video communication while maintaining secure data management and scalable backend infrastructure.

## System Architecture

### Architecture Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Layer                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  iOS App (SwiftUI + Combine)                               │ │
│  │  - User Interface                                          │ │
│  │  - Local State Management                                  │ │
│  │  - Video Call Interface                                    │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ├──────────────────┐
                              │                  │
                              ▼                  ▼
┌───────────────────────────────────┐  ┌──────────────────────────┐
│   Video Infrastructure Layer      │  │  Serverless Logic Layer  │
│  ┌─────────────────────────────┐  │  │  ┌────────────────────┐ │
│  │  Daily.co SDK               │  │  │  │  Firebase Functions│ │
│  │  - WebRTC P2P Connection   │  │  │  │  - Trust Score     │ │
│  │  - Video/Audio Streaming    │  │  │  │  - Matchmaking     │ │
│  │  - Call Management          │  │  │  │  - Business Logic  │ │
│  └─────────────────────────────┘  │  │  └────────────────────┘ │
└───────────────────────────────────┘  │  ┌────────────────────┐ │
                                        │  │  Cloud Functions   │ │
                                        │  │  - API Endpoints   │ │
                                        │  │  - Data Processing │ │
                                        │  └────────────────────┘ │
                                        │  ┌────────────────────┐ │
                                        │  │  Cloud Firestore   │ │
                                        │  │  - User Data       │ │
                                        │  │  - Match Data      │ │
                                        │  │  - Session Data    │ │
                                        │  └────────────────────┘ │
                                        └──────────────────────────┘
```

## Layer Descriptions

### 1. Client Layer (iOS Application)
**Technology Stack:**
- SwiftUI for declarative UI
- Combine framework for reactive state management
- URLSession for API communication

**Responsibilities:**
- Render user interface
- Handle user interactions
- Manage local application state
- Display video call interface
- Communicate with backend APIs

**Key Features:**
- Native iOS performance
- Reactive UI updates
- Offline capability (limited)
- Push notifications

### 2. Video Infrastructure Layer (Daily.co)
**Technology Stack:**
- Daily.co SDK
- WebRTC protocol

**Responsibilities:**
- Establish peer-to-peer video connections
- Handle video/audio streaming
- Manage call quality and bandwidth
- Provide call controls (mute, camera, etc.)

**Key Features:**
- Low-latency video streaming
- Automatic quality adjustment
- Cross-platform compatibility
- Secure encrypted connections

**Why Separate Layer:**
- Prevents video traffic from overwhelming database
- Isolates performance-intensive operations
- Allows independent scaling
- Reduces backend load

### 3. Serverless Logic Layer (Firebase/Google Cloud)
**Technology Stack:**
- Firebase Functions (Node.js/TypeScript)
- Google Cloud Functions
- Cloud Firestore (NoSQL database)
- Firebase Authentication

**Responsibilities:**
- Execute sensitive business logic
- Calculate trust scores
- Run matchmaking algorithms
- Manage user authentication
- Store and retrieve data
- Send notifications

**Key Features:**
- Auto-scaling based on demand
- Pay-per-use pricing
- Secure execution environment
- Cannot be manipulated by clients
- Global distribution

## Data Flow

### User Authentication Flow
```
1. User opens app → Client Layer
2. User enters credentials → Client Layer
3. Auth request → Firebase Auth (Serverless Layer)
4. Token generated → Returned to Client
5. Token stored locally → Client Layer
```

### Video Call Flow
```
1. User initiates call → Client Layer
2. Request call token → Serverless Layer
3. Create Daily.co room → Video Infrastructure Layer
4. Return room URL → Client Layer
5. Join video call → Video Infrastructure Layer (P2P)
6. Log call metadata → Serverless Layer
```

### Matchmaking Flow
```
1. User profile data → Serverless Layer (Firestore)
2. Trigger matchmaking function → Cloud Functions
3. Calculate compatibility → Serverless Logic
4. Generate matches → Cloud Functions
5. Update user matches → Firestore
6. Notify users → Push Notification Service
7. Display matches → Client Layer
```

## Security Architecture

### Client Layer Security
- Secure token storage (Keychain)
- Certificate pinning for API calls
- Input validation
- Encrypted local storage

### Video Layer Security
- End-to-end encryption (WebRTC)
- Temporary room tokens
- Automatic session expiration
- No video recording by default

### Backend Security
- Firebase Authentication
- Role-based access control
- Firestore security rules
- Function-level authentication
- Rate limiting
- Input sanitization

## Scalability Strategy

### Horizontal Scaling
- Firebase Functions auto-scale based on load
- Daily.co handles video infrastructure scaling
- Firestore automatically distributes data

### Performance Optimization
- Client-side caching
- Lazy loading of user profiles
- Image optimization and CDN delivery
- Database query optimization
- Connection pooling

## Development Environment Setup

### Prerequisites
- Xcode 15+ (for iOS development)
- Node.js 18+ (for Firebase Functions)
- Firebase CLI
- Daily.co account
- Google Cloud account

### Environment Variables
```bash
# Firebase Configuration
FIREBASE_PROJECT_ID=toodles-app
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=toodles-app.firebaseapp.com

# Daily.co Configuration
DAILY_API_KEY=your_daily_api_key
DAILY_DOMAIN=toodles.daily.co

# Google Cloud
GOOGLE_CLOUD_PROJECT=toodles-app
GOOGLE_APPLICATION_CREDENTIALS=path/to/credentials.json
```

## Deployment Strategy

### Development Environment
- Local iOS simulator
- Firebase emulator suite
- Daily.co test domain

### Staging Environment
- TestFlight for iOS
- Firebase staging project
- Daily.co staging domain

### Production Environment
- App Store distribution
- Firebase production project
- Daily.co production domain
- CDN for static assets

## Monitoring and Logging

### Client Layer
- Crashlytics for crash reporting
- Analytics for user behavior
- Performance monitoring

### Backend Layer
- Cloud Functions logs
- Firestore usage metrics
- Error tracking
- Performance monitoring

### Video Layer
- Daily.co analytics
- Call quality metrics
- Connection statistics

## Disaster Recovery

### Backup Strategy
- Daily Firestore backups
- User data export capability
- Configuration backups

### Failover Strategy
- Multi-region Firestore deployment
- Daily.co automatic failover
- Client-side retry logic

## Future Enhancements

### Planned Improvements
1. Machine learning-based matchmaking
2. Video message recording
3. In-app messaging
4. Advanced profile customization
5. Social media integration
6. Payment processing integration

### Technical Debt
- Implement comprehensive unit tests
- Add integration tests
- Improve error handling
- Enhance offline capabilities
- Optimize bundle size

## Team Responsibilities

### iOS Development
- Alan Tsan
- Drew Butler

### Backend Development
- Danny Shtansky
- Chaitanya Talluri

### Video Infrastructure
- Vincent Polanco

## References
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Daily.co Documentation](https://docs.daily.co/)
- [WebRTC Specification](https://webrtc.org/)

---
**Document Version:** 1.0  
**Last Updated:** February 25, 2026  
**Author:** Danny Shtansky  
**Status:** Initial Architecture Design
