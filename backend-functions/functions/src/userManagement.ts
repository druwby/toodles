import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Triggered when a new user is created
 */
export async function onUserCreated(user: admin.auth.UserRecord): Promise<void> {
  const userId = user.uid;
  const email = user.email || '';
  const displayName = user.displayName || 'Anonymous';

  try {
    // Create user document in Firestore
    await db.collection('users').doc(userId).set({
      uid: userId,
      email,
      displayName,
      emailVerified: user.emailVerified || false,
      phoneVerified: false,
      photoVerified: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastActive: admin.firestore.FieldValue.serverTimestamp(),
      status: 'active',
      profileComplete: false,
    });

    // Initialize trust score
    await db.collection('trustScores').doc(userId).set({
      userId,
      score: 50, // Start at neutral
      completedCalls: 0,
      totalCallDuration: 0,
      profileCompleteness: 0,
      verificationStatus: 'none',
      reportCount: 0,
      positiveReviews: 0,
      negativeReviews: 0,
      accountAge: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send welcome email
    await sendWelcomeEmail(email, displayName);

    functions.logger.info(`User created: ${userId}`);
  } catch (error) {
    functions.logger.error('Error in onUserCreated:', error);
    throw error;
  }
}

/**
 * Triggered when a user is deleted
 */
export async function onUserDeleted(user: admin.auth.UserRecord): Promise<void> {
  const userId = user.uid;

  try {
    // Delete user document
    await db.collection('users').doc(userId).delete();

    // Delete trust score
    await db.collection('trustScores').doc(userId).delete();

    // Delete user's matches
    const matchesSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('matches')
      .get();

    const batch = db.batch();
    matchesSnapshot.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    // Anonymize video sessions
    await anonymizeVideoSessions(userId);

    // Anonymize reviews
    await anonymizeReviews(userId);

    functions.logger.info(`User deleted: ${userId}`);
  } catch (error) {
    functions.logger.error('Error in onUserDeleted:', error);
    throw error;
  }
}

/**
 * Sends welcome email to new user
 */
async function sendWelcomeEmail(email: string, displayName: string): Promise<void> {
  try {
    // In production, integrate with email service (SendGrid, Mailgun, etc.)
    functions.logger.info(`Welcome email would be sent to: ${email}`);
    
    // Placeholder for email service integration
    // await emailService.send({
    //   to: email,
    //   subject: 'Welcome to Toodles!',
    //   template: 'welcome',
    //   data: { displayName }
    // });
  } catch (error) {
    functions.logger.error('Error sending welcome email:', error);
    // Don't throw - email failure shouldn't block user creation
  }
}

/**
 * Anonymizes video sessions when user is deleted
 */
async function anonymizeVideoSessions(userId: string): Promise<void> {
  try {
    const sessionsSnapshot = await db
      .collection('videoSessions')
      .where('initiatorId', '==', userId)
      .get();

    const recipientSessionsSnapshot = await db
      .collection('videoSessions')
      .where('recipientId', '==', userId)
      .get();

    const batch = db.batch();

    sessionsSnapshot.forEach((doc) => {
      batch.update(doc.ref, {
        initiatorId: '[deleted]',
        initiatorToken: null,
      });
    });

    recipientSessionsSnapshot.forEach((doc) => {
      batch.update(doc.ref, {
        recipientId: '[deleted]',
        recipientToken: null,
      });
    });

    await batch.commit();

    functions.logger.info(`Anonymized video sessions for user ${userId}`);
  } catch (error) {
    functions.logger.error('Error anonymizing video sessions:', error);
    throw error;
  }
}

/**
 * Anonymizes reviews when user is deleted
 */
async function anonymizeReviews(userId: string): Promise<void> {
  try {
    const reviewsSnapshot = await db
      .collection('reviews')
      .where('reviewerId', '==', userId)
      .get();

    const batch = db.batch();

    reviewsSnapshot.forEach((doc) => {
      batch.update(doc.ref, {
        reviewerId: '[deleted]',
        reviewerName: '[Deleted User]',
      });
    });

    await batch.commit();

    functions.logger.info(`Anonymized reviews for user ${userId}`);
  } catch (error) {
    functions.logger.error('Error anonymizing reviews:', error);
    throw error;
  }
}
