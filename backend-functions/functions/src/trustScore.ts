import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface TrustScoreData {
  score: number;
  completedCalls: number;
  totalCallDuration: number;
  profileCompleteness: number;
  verificationStatus: string;
  reportCount: number;
  positiveReviews: number;
  negativeReviews: number;
  accountAge: number;
  lastUpdated: Date;
}

/**
 * Calculates comprehensive trust score for a user
 */
export async function calculateTrustScore(
  data: { userId?: string },
  context: functions.https.CallableContext
): Promise<TrustScoreData> {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = data.userId || context.auth.uid;

  // Users can only calculate their own trust score
  if (userId !== context.auth.uid) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Cannot calculate trust score for another user'
    );
  }

  try {
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();

    // Get existing trust score data
    const trustScoreDoc = await db.collection('trustScores').doc(userId).get();
    const existingData = trustScoreDoc.data() || {};

    // Calculate profile completeness (0-100)
    const profileCompleteness = calculateProfileCompleteness(userData);

    // Get video session statistics
    const sessionStats = await getVideoSessionStats(userId);

    // Get review statistics
    const reviewStats = await getReviewStats(userId);

    // Get report count
    const reportCount = await getReportCount(userId);

    // Calculate account age in days
    const accountAge = Math.floor(
      (Date.now() - userData?.createdAt?.toMillis()) / (1000 * 60 * 60 * 24)
    );

    // Calculate base score (0-100)
    let score = 50; // Start at neutral

    // Profile completeness bonus (0-15 points)
    score += (profileCompleteness / 100) * 15;

    // Verification bonus (0-10 points)
    if (userData?.emailVerified) score += 5;
    if (userData?.phoneVerified) score += 5;

    // Video call history bonus (0-20 points)
    score += Math.min(20, sessionStats.completedCalls * 2);
    score += Math.min(10, Math.floor(sessionStats.totalDuration / 3600)); // 1 point per hour

    // Review score adjustment (-30 to +20 points)
    const reviewScore = calculateReviewScore(
      reviewStats.positiveReviews,
      reviewStats.negativeReviews
    );
    score += reviewScore;

    // Account age bonus (0-10 points)
    score += Math.min(10, Math.floor(accountAge / 30)); // 1 point per month

    // Report penalty (-5 points per report, max -50)
    score -= Math.min(50, reportCount * 5);

    // Clamp score between 0 and 100
    score = Math.max(0, Math.min(100, score));

    const trustScoreData: TrustScoreData = {
      score: Math.round(score),
      completedCalls: sessionStats.completedCalls,
      totalCallDuration: sessionStats.totalDuration,
      profileCompleteness,
      verificationStatus: getVerificationStatus(userData),
      reportCount,
      positiveReviews: reviewStats.positiveReviews,
      negativeReviews: reviewStats.negativeReviews,
      accountAge,
      lastUpdated: new Date(),
    };

    // Save to Firestore
    await db.collection('trustScores').doc(userId).set({
      ...trustScoreData,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    functions.logger.info(`Trust score calculated for user ${userId}: ${score}`);

    return trustScoreData;
  } catch (error) {
    functions.logger.error('Error calculating trust score:', error);
    throw new functions.https.HttpsError('internal', 'Failed to calculate trust score');
  }
}

/**
 * Updates trust score incrementally
 */
export async function updateTrustScore(
  userId: string,
  adjustment: number,
  reason: string
): Promise<void> {
  try {
    const trustScoreRef = db.collection('trustScores').doc(userId);
    
    await trustScoreRef.set({
      score: admin.firestore.FieldValue.increment(adjustment),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastAdjustment: {
        amount: adjustment,
        reason,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      },
    }, { merge: true });

    functions.logger.info(`Trust score updated for ${userId}: ${adjustment} (${reason})`);
  } catch (error) {
    functions.logger.error('Error updating trust score:', error);
    throw error;
  }
}

/**
 * Calculates profile completeness percentage
 */
function calculateProfileCompleteness(userData: any): number {
  const requiredFields = [
    'displayName',
    'email',
    'age',
    'gender',
    'bio',
    'interests',
    'photos',
    'location',
  ];

  let completedFields = 0;

  for (const field of requiredFields) {
    if (userData?.[field]) {
      if (Array.isArray(userData[field])) {
        if (userData[field].length > 0) completedFields++;
      } else if (typeof userData[field] === 'string') {
        if (userData[field].trim().length > 0) completedFields++;
      } else {
        completedFields++;
      }
    }
  }

  return Math.round((completedFields / requiredFields.length) * 100);
}

/**
 * Gets video session statistics for a user
 */
async function getVideoSessionStats(userId: string): Promise<{
  completedCalls: number;
  totalDuration: number;
}> {
  try {
    const sessionsSnapshot = await db
      .collection('videoSessions')
      .where('status', '==', 'ended')
      .where('initiatorId', '==', userId)
      .get();

    const recipientSessionsSnapshot = await db
      .collection('videoSessions')
      .where('status', '==', 'ended')
      .where('recipientId', '==', userId)
      .get();

    let completedCalls = 0;
    let totalDuration = 0;

    sessionsSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.duration > 30) { // Only count calls longer than 30 seconds
        completedCalls++;
        totalDuration += data.duration;
      }
    });

    recipientSessionsSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.duration > 30) {
        completedCalls++;
        totalDuration += data.duration;
      }
    });

    return { completedCalls, totalDuration };
  } catch (error) {
    functions.logger.error('Error getting video session stats:', error);
    return { completedCalls: 0, totalDuration: 0 };
  }
}

/**
 * Gets review statistics for a user
 */
async function getReviewStats(userId: string): Promise<{
  positiveReviews: number;
  negativeReviews: number;
}> {
  try {
    const reviewsSnapshot = await db
      .collection('reviews')
      .where('reviewedUserId', '==', userId)
      .get();

    let positiveReviews = 0;
    let negativeReviews = 0;

    reviewsSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.rating >= 4) {
        positiveReviews++;
      } else if (data.rating <= 2) {
        negativeReviews++;
      }
    });

    return { positiveReviews, negativeReviews };
  } catch (error) {
    functions.logger.error('Error getting review stats:', error);
    return { positiveReviews: 0, negativeReviews: 0 };
  }
}

/**
 * Gets report count for a user
 */
async function getReportCount(userId: string): Promise<number> {
  try {
    const reportsSnapshot = await db
      .collection('reports')
      .where('reportedUserId', '==', userId)
      .where('status', '==', 'pending')
      .get();

    return reportsSnapshot.size;
  } catch (error) {
    functions.logger.error('Error getting report count:', error);
    return 0;
  }
}

/**
 * Calculates review score contribution
 */
function calculateReviewScore(positiveReviews: number, negativeReviews: number): number {
  const totalReviews = positiveReviews + negativeReviews;
  
  if (totalReviews === 0) {
    return 0;
  }

  const positiveRatio = positiveReviews / totalReviews;
  
  // Scale from -30 to +20
  if (positiveRatio >= 0.8) {
    return 20;
  } else if (positiveRatio >= 0.6) {
    return 10;
  } else if (positiveRatio >= 0.4) {
    return 0;
  } else if (positiveRatio >= 0.2) {
    return -15;
  } else {
    return -30;
  }
}

/**
 * Gets verification status string
 */
function getVerificationStatus(userData: any): string {
  const statuses: string[] = [];
  
  if (userData?.emailVerified) statuses.push('email');
  if (userData?.phoneVerified) statuses.push('phone');
  if (userData?.photoVerified) statuses.push('photo');
  
  return statuses.length > 0 ? statuses.join(',') : 'none';
}
