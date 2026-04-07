// ReportingService.swift
// Toodles
//
// TDV-73: Implement ReportingService for user content moderation

import Foundation
import FirebaseFirestore

enum ReportReason: String, CaseIterable, Codable {
    case inappropriateContent = "inappropriate_content"
    case harassment = "harassment"
    case fakeProfile = "fake_profile"
    case spam = "spam"
    case other = "other"
}

struct UserReport: Codable, Identifiable {
    var id: String
    let reporterUID: String
    let reportedUID: String
    let reason: ReportReason
    let description: String
    let timestamp: Date
    var status: ReportStatus

    enum ReportStatus: String, Codable {
        case pending = "pending"
        case reviewed = "reviewed"
        case resolved = "resolved"
    }
}

@MainActor
final class ReportingService: ObservableObject {

    static let shared = ReportingService()
    private let db = Firestore.firestore()

    @Published var isSubmitting = false
    @Published var submissionError: Error?

    private init() {}

    func submitReport(
        reporterUID: String,
        reportedUID: String,
        reason: ReportReason,
        description: String
    ) async throws {
        isSubmitting = true
        defer { isSubmitting = false }

        let report = UserReport(
            id: UUID().uuidString,
            reporterUID: reporterUID,
            reportedUID: reportedUID,
            reason: reason,
            description: description,
            timestamp: Date(),
            status: .pending
        )

        let reportData: [String: Any] = [
            "id": report.id,
            "reporterUID": report.reporterUID,
            "reportedUID": report.reportedUID,
            "reason": report.reason.rawValue,
            "description": report.description,
            "timestamp": Timestamp(date: report.timestamp),
            "status": report.status.rawValue
        ]

        try await db.collection("reports").document(report.id).setData(reportData)

        try await db.collection("users").document(reportedUID).updateData([
            "reportCount": FieldValue.increment(Int64(1)),
            "lastReportedAt": Timestamp(date: Date())
        ])
    }

    func blockUser(blockerUID: String, blockedUID: String) async throws {
        try await db.collection("users")
            .document(blockerUID)
            .collection("blockedUsers")
            .document(blockedUID)
            .setData(["blockedAt": Timestamp(date: Date())])
    }

    func isUserBlocked(blockerUID: String, blockedUID: String) async -> Bool {
        do {
            let doc = try await db.collection("users")
                .document(blockerUID)
                .collection("blockedUsers")
                .document(blockedUID)
                .getDocument()
            return doc.exists
        } catch {
            return false
        }
    }
}
