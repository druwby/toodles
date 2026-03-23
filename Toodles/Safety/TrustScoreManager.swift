// TrustScoreManager.swift
// Toodles
//
// TDV-74: Build TrustScoreManager with account verification logic

import Foundation
import FirebaseFirestore
import FirebaseAuth

enum VerificationStatus: String, Codable {
    case unverified = "unverified"
    case emailVerified = "email_verified"
    case phoneVerified = "phone_verified"
    case idVerified = "id_verified"
}

struct TrustScore: Codable {
    let uid: String
    var score: Double
    var verificationStatus: VerificationStatus
    var profileCompleteness: Double
    var accountAgeDays: Int
    var reportCount: Int
    var lastUpdated: Date

    var trustLevel: TrustLevel {
        switch score {
        case 80...100: return .high
        case 50..<80:  return .medium
        default:       return .low
        }
    }

    enum TrustLevel: String {
        case high   = "High Trust"
        case medium = "Medium Trust"
        case low    = "Low Trust"
    }
}

@MainActor
final class TrustScoreManager: ObservableObject {

    static let shared = TrustScoreManager()
    private let db = Firestore.firestore()

    @Published var currentUserTrustScore: TrustScore?
    @Published var isLoading = false

    private init() {}

    func calculateTrustScore(for uid: String) async throws -> TrustScore {
        isLoading = true
        defer { isLoading = false }

        let userDoc = try await db.collection("users").document(uid).getDocument()
        guard let data = userDoc.data() else {
            throw TrustScoreError.userNotFound
        }

        let reportCount = data["reportCount"] as? Int ?? 0
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let accountAgeDays = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0

        let hasPhoto = (data["profilePhotoURL"] as? String) != nil
        let hasBio = (data["bio"] as? String) != nil
        let hasName = (data["displayName"] as? String) != nil
        let completenessScore = [hasPhoto, hasBio, hasName].filter { $0 }.count

        let verificationRaw = data["verificationStatus"] as? String ?? "unverified"
        let verificationStatus = VerificationStatus(rawValue: verificationRaw) ?? .unverified

        var score: Double = 50.0

        switch verificationStatus {
        case .idVerified:    score += 30
        case .phoneVerified: score += 20
        case .emailVerified: score += 10
        case .unverified:    break
        }

        score += Double(completenessScore) * (10.0 / 3.0)
        score += min(Double(accountAgeDays) / 18.0, 10.0)
        score -= Double(reportCount) * 5.0
        score = max(0, min(100, score))

        let trustScore = TrustScore(
            uid: uid,
            score: score,
            verificationStatus: verificationStatus,
            profileCompleteness: Double(completenessScore) / 3.0,
            accountAgeDays: accountAgeDays,
            reportCount: reportCount,
            lastUpdated: Date()
        )

        try await db.collection("trustScores").document(uid).setData([
            "uid": uid,
            "score": score,
            "verificationStatus": verificationStatus.rawValue,
            "reportCount": reportCount,
            "lastUpdated": Timestamp(date: Date())
        ])

        currentUserTrustScore = trustScore
        return trustScore
    }

    func verifyEmail(for uid: String) async throws {
        try await db.collection("users").document(uid).updateData([
            "verificationStatus": VerificationStatus.emailVerified.rawValue
        ])
        _ = try await calculateTrustScore(for: uid)
    }

    func fetchTrustScore(for uid: String) async throws -> TrustScore? {
        let doc = try await db.collection("trustScores").document(uid).getDocument()
        guard let data = doc.data() else { return nil }

        return TrustScore(
            uid: uid,
            score: data["score"] as? Double ?? 0,
            verificationStatus: VerificationStatus(rawValue: data["verificationStatus"] as? String ?? "unverified") ?? .unverified,
            profileCompleteness: 0,
            accountAgeDays: 0,
            reportCount: data["reportCount"] as? Int ?? 0,
            lastUpdated: (data["lastUpdated"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    enum TrustScoreError: Error {
        case userNotFound
        case calculationFailed
    }
}
