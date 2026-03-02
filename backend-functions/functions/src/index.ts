import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as express from 'express';
import * as cors from 'cors';

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

// Initialize Express app for HTTP functions
const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Import function modules
import { createVideoSession, endVideoSession } from './videoSessions';
import { calculateTrustScore, updateTrustScore } from './trustScore';
import { findMatches, createMatch } from './matchmaking';
import { onUserCreated, onUserDeleted } from './userManagement';

// Export HTTP functions
export const api = functions.https.onRequest(app);

// Export callable functions
export const createVideoSessionCallable = functions.https.onCall(createVideoSession);
export const endVideoSessionCallable = functions.https.onCall(endVideoSession);
export const calculateTrustScoreCallable = functions.https.onCall(calculateTrustScore);
export const findMatchesCallable = functions.https.onCall(findMatches);

// Export triggered functions
export const onUserCreatedTrigger = functions.auth.user().onCreate(onUserCreated);
export const onUserDeletedTrigger = functions.auth.user().onDelete(onUserDeleted);

// Export scheduled functions
export const dailyMatchmaking = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    functions.logger.info('Running daily matchmaking...');
    // Implement daily matchmaking logic
    return null;
  });

export const weeklyTrustScoreUpdate = functions.pubsub
  .schedule('every sunday 00:00')
  .timeZone('America/Los_Angeles')
  .onRun(async (context) => {
    functions.logger.info('Running weekly trust score update...');
    // Implement weekly trust score recalculation
    return null;
  });

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// API routes
app.post('/api/video/session', async (req, res) => {
  try {
    const { recipientId } = req.body;
    const token = req.headers.authorization?.split('Bearer ')[1];
    
    if (!token) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    
    const decodedToken = await auth.verifyIdToken(token);
    const result = await createVideoSession({ 
      recipientId, 
      initiatorId: decodedToken.uid 
    }, { auth: { uid: decodedToken.uid } } as any);
    
    res.status(200).json(result);
  } catch (error) {
    functions.logger.error('Error creating video session:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/matches/find', async (req, res) => {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    
    if (!token) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    
    const decodedToken = await auth.verifyIdToken(token);
    const result = await findMatches({}, { auth: { uid: decodedToken.uid } } as any);
    
    res.status(200).json(result);
  } catch (error) {
    functions.logger.error('Error finding matches:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/user/:userId/trust-score', async (req, res) => {
  try {
    const { userId } = req.params;
    const token = req.headers.authorization?.split('Bearer ')[1];
    
    if (!token) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    
    const decodedToken = await auth.verifyIdToken(token);
    
    // Users can only view their own trust score
    if (decodedToken.uid !== userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    
    const trustScoreDoc = await db.collection('trustScores').doc(userId).get();
    
    if (!trustScoreDoc.exists) {
      return res.status(404).json({ error: 'Trust score not found' });
    }
    
    res.status(200).json(trustScoreDoc.data());
  } catch (error) {
    functions.logger.error('Error fetching trust score:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
