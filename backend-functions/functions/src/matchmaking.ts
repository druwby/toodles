import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface MatchResult {
  userId: string;
  displayName: string;
  age: number;
  photos: string[];
  bio: string;
  matchScore: number;
  commonInterests: string[];
}

/**
 * Finds potential matches for a user
 */
export async function findMatches(
  data: { limit?: number },
  context: functions.https.CallableContext
): Promise<MatchResult[]> {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const limit = data.limit || 10;

  try {
    // Get current user's profile
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User profile not found');
    }

    const userData = userDoc.data();

    // Get user's preferences
    const preferences = userData?.preferences || {};
    const userInterests = userData?.interests || [];
    const userAge = userData?.age || 25;
    const userGender = userData?.gender || 'other';

    // Get users already matched or rejected
    const existingMatchesSnapshot = await db
      .collection('matches')
      .where('user1Id', '==', userId)
      .get();

    const existingMatchIds = new Set<string>();
    existingMatchesSnapshot.forEach((doc) => {
      const data = doc.data();
      existingMatchIds.add(data.user2Id);
    });

    // Also check reverse matches
    const reverseMatchesSnapshot = await db
      .collection('matches')
      .where('user2Id', '==', userId)
      .get();

    reverseMatchesSnapshot.forEach((doc) => {
      const data = doc.data();
      existingMatchIds.add(data.user1Id);
    });

    // Query potential matches based on preferences
    let query = db.collection('users')
      .where('gender', '==', preferences.interestedIn || 'female')
      .limit(50); // Get more candidates than needed for scoring

    const candidatesSnapshot = await query.get();

    const matches: MatchResult[] = [];

    for (const candidateDoc of candidatesSnapshot.docs) {
      const candidateId = candidateDoc.id;

      // Skip if already matched or is self
      if (candidateId === userId || existingMatchIds.has(candidateId)) {
        continue;
      }

      const candidateData = candidateDoc.data();

      // Check age preference
      const candidateAge = candidateData.age || 25;
      const minAge = preferences.minAge || 18;
      const maxAge = preferences.maxAge || 100;

      if (candidateAge < minAge || candidateAge > maxAge) {
        continue;
      }

      // Calculate match score
      const matchScore = await calculateMatchScore(
        userId,
        candidateId,
        userData,
        candidateData
      );

      // Only include matches with score > 30
      if (matchScore > 30) {
        const commonInterests = findCommonInterests(
          userInterests,
          candidateData.interests || []
        );

        matches.push({
          userId: candidateId,
          displayName: candidateData.displayName || 'Anonymous',
          age: candidateAge,
          photos: candidateData.photos || [],
          bio: candidateData.bio || '',
          matchScore,
          commonInterests,
        });
      }
    }

    // Sort by match score descending
    matches.sort((a, b) => b.matchScore - a.matchScore);

    // Return top N matches
    const topMatches = matches.slice(0, limit);

    // Store matches in database
    await storeMatches(userId, topMatches);

    functions.logger.info(`Found ${topMatches.length} matches for user ${userId}`);

    return topMatches;
  } catch (error) {
    functions.logger.error('Error finding matches:', error);
    throw new functions.https.HttpsError('internal', 'Failed to find matches');
  }
}

/**
 * Creates a match between two users
 */
export async function createMatch(
  user1Id: string,
  user2Id: string,
  matchScore: number
): Promise<string> {
  try {
    const matchRef = db.collection('matches').doc();

    await matchRef.set({
      matchId: matchRef.id,
      user1Id,
      user2Id,
      matchScore,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      user1Action: null,
      user2Action: null,
      mutualMatch: false,
    });

    functions.logger.info(`Match created: ${matchRef.id} (${user1Id} <-> ${user2Id})`);

    return matchRef.id;
  } catch (error) {
    functions.logger.error('Error creating match:', error);
    throw error;
  }
}

/**
 * Calculates match score between two users (0-100)
 */
async function calculateMatchScore(
  user1Id: string,
  user2Id: string,
  user1Data: any,
  user2Data: any
): Promise<number> {
  let score = 0;

  // Interest compatibility (0-30 points)
  const interests1 = user1Data.interests || [];
  const interests2 = user2Data.interests || [];
  const commonInterests = findCommonInterests(interests1, interests2);
  const interestScore = Math.min(30, commonInterests.length * 6);
  score += interestScore;

  // Age compatibility (0-20 points)
  const age1 = user1Data.age || 25;
  const age2 = user2Data.age || 25;
  const ageDiff = Math.abs(age1 - age2);
  const ageScore = Math.max(0, 20 - ageDiff * 2);
  score += ageScore;

  // Location proximity (0-15 points)
  if (user1Data.location && user2Data.location) {
    const locationScore = calculateLocationScore(
      user1Data.location,
      user2Data.location
    );
    score += locationScore;
  }

  // Trust score compatibility (0-15 points)
  const trust1 = await getTrustScore(user1Id);
  const trust2 = await getTrustScore(user2Id);
  const avgTrust = (trust1 + trust2) / 2;
  const trustScore = (avgTrust / 100) * 15;
  score += trustScore;

  // Profile completeness (0-10 points)
  const completeness1 = calculateCompleteness(user1Data);
  const completeness2 = calculateCompleteness(user2Data);
  const avgCompleteness = (completeness1 + completeness2) / 2;
  const completenessScore = (avgCompleteness / 100) * 10;
  score += completenessScore;

  // Activity level (0-10 points)
  const activity1 = user1Data.lastActive?.toMillis() || 0;
  const activity2 = user2Data.lastActive?.toMillis() || 0;
  const daysSinceActive1 = (Date.now() - activity1) / (1000 * 60 * 60 * 24);
  const daysSinceActive2 = (Date.now() - activity2) / (1000 * 60 * 60 * 24);
  const activityScore = Math.max(0, 10 - (daysSinceActive1 + daysSinceActive2) / 2);
  score += activityScore;

  return Math.round(Math.min(100, score));
}

/**
 * Finds common interests between two arrays
 */
function findCommonInterests(interests1: string[], interests2: string[]): string[] {
  return interests1.filter((interest) =>
    interests2.some((i) => i.toLowerCase() === interest.toLowerCase())
  );
}

/**
 * Calculates location-based score
 */
function calculateLocationScore(location1: any, location2: any): number {
  // Simplified distance calculation
  // In production, use proper geospatial queries
  
  if (!location1.lat || !location2.lat) {
    return 0;
  }

  const distance = calculateDistance(
    location1.lat,
    location1.lng,
    location2.lat,
    location2.lng
  );

  // Score based on distance (in miles)
  if (distance < 10) return 15;
  if (distance < 25) return 12;
  if (distance < 50) return 8;
  if (distance < 100) return 4;
  return 0;
}

/**
 * Calculates distance between two coordinates (Haversine formula)
 */
function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 3959; // Earth's radius in miles
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(degrees: number): number {
  return degrees * (Math.PI / 180);
}

/**
 * Gets trust score for a user
 */
async function getTrustScore(userId: string): Promise<number> {
  try {
    const trustDoc = await db.collection('trustScores').doc(userId).get();
    return trustDoc.data()?.score || 50;
  } catch (error) {
    return 50; // Default neutral score
  }
}

/**
 * Calculates profile completeness
 */
function calculateCompleteness(userData: any): number {
  const fields = ['displayName', 'age', 'gender', 'bio', 'interests', 'photos'];
  let completed = 0;

  for (const field of fields) {
    if (userData[field]) {
      if (Array.isArray(userData[field]) && userData[field].length > 0) {
        completed++;
      } else if (typeof userData[field] === 'string' && userData[field].length > 0) {
        completed++;
      } else if (typeof userData[field] === 'number') {
        completed++;
      }
    }
  }

  return (completed / fields.length) * 100;
}

/**
 * Stores matches in user's match subcollection
 */
async function storeMatches(userId: string, matches: MatchResult[]): Promise<void> {
  try {
    const batch = db.batch();

    for (const match of matches) {
      const matchRef = db
        .collection('users')
        .doc(userId)
        .collection('matches')
        .doc(match.userId);

      batch.set(matchRef, {
        ...match,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        viewed: false,
        liked: null,
      });
    }

    await batch.commit();

    functions.logger.info(`Stored ${matches.length} matches for user ${userId}`);
  } catch (error) {
    functions.logger.error('Error storing matches:', error);
    throw error;
  }
}
