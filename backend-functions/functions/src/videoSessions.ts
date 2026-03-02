import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

const db = admin.firestore();

// Daily.co API configuration
const DAILY_API_KEY = functions.config().daily?.api_key || process.env.DAILY_API_KEY;
const DAILY_API_URL = 'https://api.daily.co/v1';

interface CreateVideoSessionData {
  recipientId: string;
  initiatorId?: string;
}

interface VideoSessionResult {
  sessionId: string;
  roomUrl: string;
  token: string;
  expiresAt: Date;
}

/**
 * Creates a new video session using Daily.co
 */
export async function createVideoSession(
  data: CreateVideoSessionData,
  context: functions.https.CallableContext
): Promise<VideoSessionResult> {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const initiatorId = context.auth.uid;
  const { recipientId } = data;

  // Validate recipient exists
  const recipientDoc = await db.collection('users').doc(recipientId).get();
  if (!recipientDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Recipient user not found');
  }

  try {
    // Create a Daily.co room
    const roomResponse = await axios.post(
      `${DAILY_API_URL}/rooms`,
      {
        properties: {
          max_participants: 2,
          enable_screenshare: false,
          enable_chat: false,
          start_video_off: false,
          start_audio_off: false,
          exp: Math.floor(Date.now() / 1000) + 3600, // 1 hour expiration
        },
      },
      {
        headers: {
          'Authorization': `Bearer ${DAILY_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    const roomUrl = roomResponse.data.url;
    const roomName = roomResponse.data.name;

    // Create tokens for both participants
    const initiatorToken = await createDailyToken(roomName, initiatorId);
    const recipientToken = await createDailyToken(roomName, recipientId);

    // Create session document in Firestore
    const sessionRef = db.collection('videoSessions').doc();
    const sessionData = {
      sessionId: sessionRef.id,
      initiatorId,
      recipientId,
      roomUrl,
      roomName,
      initiatorToken,
      recipientToken,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: new Date(Date.now() + 3600000), // 1 hour
      startedAt: null,
      endedAt: null,
      duration: 0,
    };

    await sessionRef.set(sessionData);

    // Send notification to recipient
    await sendVideoCallNotification(recipientId, initiatorId, sessionRef.id);

    functions.logger.info(`Video session created: ${sessionRef.id}`);

    return {
      sessionId: sessionRef.id,
      roomUrl,
      token: initiatorToken,
      expiresAt: sessionData.expiresAt,
    };
  } catch (error) {
    functions.logger.error('Error creating video session:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create video session');
  }
}

/**
 * Ends an active video session
 */
export async function endVideoSession(
  data: { sessionId: string },
  context: functions.https.CallableContext
): Promise<{ success: boolean }> {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { sessionId } = data;
  const userId = context.auth.uid;

  try {
    const sessionRef = db.collection('videoSessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Session not found');
    }

    const sessionData = sessionDoc.data();

    // Verify user is part of the session
    if (sessionData?.initiatorId !== userId && sessionData?.recipientId !== userId) {
      throw new functions.https.HttpsError('permission-denied', 'User not part of this session');
    }

    // Calculate duration if session was started
    let duration = 0;
    if (sessionData?.startedAt) {
      duration = Math.floor((Date.now() - sessionData.startedAt.toMillis()) / 1000);
    }

    // Update session status
    await sessionRef.update({
      status: 'ended',
      endedAt: admin.firestore.FieldValue.serverTimestamp(),
      duration,
    });

    // Delete Daily.co room
    if (sessionData?.roomName) {
      await deleteDailyRoom(sessionData.roomName);
    }

    // Update trust scores for both participants
    await updateTrustScoreAfterCall(sessionData.initiatorId, sessionData.recipientId, duration);

    functions.logger.info(`Video session ended: ${sessionId}`);

    return { success: true };
  } catch (error) {
    functions.logger.error('Error ending video session:', error);
    throw new functions.https.HttpsError('internal', 'Failed to end video session');
  }
}

/**
 * Creates a Daily.co meeting token for a user
 */
async function createDailyToken(roomName: string, userId: string): Promise<string> {
  try {
    const tokenResponse = await axios.post(
      `${DAILY_API_URL}/meeting-tokens`,
      {
        properties: {
          room_name: roomName,
          user_id: userId,
          is_owner: false,
          exp: Math.floor(Date.now() / 1000) + 3600,
        },
      },
      {
        headers: {
          'Authorization': `Bearer ${DAILY_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    return tokenResponse.data.token;
  } catch (error) {
    functions.logger.error('Error creating Daily token:', error);
    throw error;
  }
}

/**
 * Deletes a Daily.co room
 */
async function deleteDailyRoom(roomName: string): Promise<void> {
  try {
    await axios.delete(`${DAILY_API_URL}/rooms/${roomName}`, {
      headers: {
        'Authorization': `Bearer ${DAILY_API_KEY}`,
      },
    });
  } catch (error) {
    functions.logger.error('Error deleting Daily room:', error);
    // Don't throw - room deletion is not critical
  }
}

/**
 * Sends a push notification for incoming video call
 */
async function sendVideoCallNotification(
  recipientId: string,
  initiatorId: string,
  sessionId: string
): Promise<void> {
  try {
    // Get initiator's profile
    const initiatorDoc = await db.collection('users').doc(initiatorId).get();
    const initiatorData = initiatorDoc.data();

    // Get recipient's FCM token
    const recipientDoc = await db.collection('users').doc(recipientId).get();
    const recipientData = recipientDoc.data();

    if (!recipientData?.fcmToken) {
      functions.logger.warn(`No FCM token for user ${recipientId}`);
      return;
    }

    // Send notification
    await admin.messaging().send({
      token: recipientData.fcmToken,
      notification: {
        title: 'Incoming Video Call',
        body: `${initiatorData?.displayName || 'Someone'} is calling you!`,
      },
      data: {
        type: 'video_call',
        sessionId,
        initiatorId,
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    });

    functions.logger.info(`Video call notification sent to ${recipientId}`);
  } catch (error) {
    functions.logger.error('Error sending video call notification:', error);
    // Don't throw - notification failure shouldn't block session creation
  }
}

/**
 * Updates trust scores after a video call
 */
async function updateTrustScoreAfterCall(
  user1Id: string,
  user2Id: string,
  duration: number
): Promise<void> {
  try {
    // Only update if call lasted more than 30 seconds
    if (duration < 30) {
      return;
    }

    // Positive trust score adjustment for completing a call
    const trustScoreAdjustment = Math.min(5, Math.floor(duration / 60)); // 1 point per minute, max 5

    const batch = db.batch();

    // Update user1's trust score
    const user1TrustRef = db.collection('trustScores').doc(user1Id);
    batch.set(
      user1TrustRef,
      {
        score: admin.firestore.FieldValue.increment(trustScoreAdjustment),
        completedCalls: admin.firestore.FieldValue.increment(1),
        totalCallDuration: admin.firestore.FieldValue.increment(duration),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Update user2's trust score
    const user2TrustRef = db.collection('trustScores').doc(user2Id);
    batch.set(
      user2TrustRef,
      {
        score: admin.firestore.FieldValue.increment(trustScoreAdjustment),
        completedCalls: admin.firestore.FieldValue.increment(1),
        totalCallDuration: admin.firestore.FieldValue.increment(duration),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await batch.commit();

    functions.logger.info(`Trust scores updated after call: ${user1Id}, ${user2Id}`);
  } catch (error) {
    functions.logger.error('Error updating trust scores:', error);
    // Don't throw - trust score update failure shouldn't block session end
  }
}
