// ReportingService.swift
// Toodles
//
// TDV-73: Implement ReportingService for user content moderation
// Updated: Added input validation and retry logic for Firestore operations

import Foundation
import FirebaseFirestore

// MARK: - Report Reason

enum ReportReason: String, CaseIterable, Codable {
    case inappropriateContent = "inappropriate_content"
    case harassment = "harassment"
    case fakeProfile = "fake_profile"
    case spam = "spam"
    case other = "other"
}

// MARK: - Validation Errors

enum ReportValidationError: LocalizedError {
    case emptyReporterUID
    case emptyReportedUID
    case selfReport
    case descriptionTooShort
    case descriptionTooLong

    var errorDescription: String? {
        switch self {
        case .emptyReporterUID:    return "Reporter UID must not be empty."
        case .emptyReportedUID:    return "Reported user UID must not be empty."
        case .selfReport:          return "You cannot report yourself."
        case .descriptionTooShort: return "Description must be at least 10 characters."
        case .descriptionTooLong:  return "Description must be 500 characters or fewer."
        }
    }
}

// MARK: - UserReport Model

struct UserReport: Codable, Identifiable {
    var id: String
    let reporterUID: String
    let reportedUID: String
    let reason: ReportReason
    let description: String
    let timestamp: Date
    var status: ReportStatus

    enum ReportStatus: String, Codable {
        case pending  = "pending"
        case reviewed = "reviewed"
        case resolved = "resolved"
    }
}

// MARK: - ReportingService

@MainActor
final class ReportingService: ObservableObject {

    static let shared = ReportingService()

    private let db = Firestore.firestore()

    /// Maximum number of retry attempts for Firestore writes.
    private let maxRetries = 3
    /// Base delay (seconds) for exponential back-off between retries.
    private let retryBaseDelay: TimeInterval = 1.0

    @Published var isSubmitting = false
    @Published var submissionError: Error?

    private init() {}

    // MARK: - Input Validation

    /// Validates all fields before submitting a report.
    /// Throws ReportValidationError describing the first failing constraint.
    private func validate(
        reporterUID: String,
        reportedUID: String,
        description: String
    ) throws {
        let trimmedReporter = reporterUID.trimmingCharacters(in: .whitespaces)
        let trimmedReported = reportedUID.trimmingCharacters(in: .whitespaces)
        let trimmedDesc     = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedReporter.isEmpty else { throw ReportValidationError.emptyReporterUID }
        guard !trimmedReported.isEmpty else { throw ReportValidationError.emptyReportedUID }
        guard trimmedReporter != trimmedReported else { throw ReportValidationError.selfReport }
        guard trimmedDesc.count >= 10 else { throw ReportValidationError.descriptionTooShort }
        guard trimmedDesc.count <= 500 else { throw ReportValidationError.descriptionTooLong }
    }

    // MARK: - Submit Report

    /// Submits a user report to Firestore with input validation and exponential back-off retry.
    func submitReport(
        reporterUID: String,
        reportedUID: String,
        reason: ReportReason,
        description: String
    ) async throws {
        // 1. Validate inputs before any network call
        try validate(reporterUID: reporterUID, reportedUID: reportedUID, description: description)

        isSubmitting = true
        submissionError = nil
        defer { isSubmitting = false }

        let report = UserReport(
            id: UUID().uuidString,
            reporterUID: reporterUID.trimmingCharacters(in: .whitespaces),
            reportedUID: reportedUID.trimmingCharacters(in: .whitespaces),
            reason: reason,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: Date(),
            status: .pending
        )

        let reportData: [String: Any] = [
            "id":          report.id,
            "reporterUID": report.reporterUID,
            "reportedUID": report.reportedUID,
            "reason":      report.reason.rawValue,
            "description": report.description,
            "timestamp":   Timestamp(date: report.timestamp),
            "status":      report.status.rawValue
        ]

        // 2. Write report document with retry
        try await withRetry(maxAttempts: maxRetries, baseDelay: retryBaseDelay) {
            try await self.db.collection("reports").document(report.id).setData(reportData)
        }

        // 3. Increment report counter on the reported user with retry
        try await withRetry(maxAttempts: maxRetries, baseDelay: retryBaseDelay) {
            try await self.db.collection("users").document(report.reportedUID).updateData([
                "reportCount":    FieldValue.increment(Int64(1)),
                "lastReportedAt": Timestamp(date: Date())
            ])
        }
    }

    // MARK: - Block User

    /// Adds the blocked user to the blocker sub-collection with input validation and retry.
    func blockUser(blockerUID: String, blockedUID: String) async throws {
        let trimmedBlocker = blockerUID.trimmingCharacters(in: .whitespaces)
        let trimmedBlocked = blockedUID.trimmingCharacters(in: .whitespaces)

        guard !trimmedBlocker.isEmpty else { throw ReportValidationError.emptyReporterUID }
        guard !trimmedBlocked.isEmpty else { throw ReportValidationError.emptyReportedUID }
        guard trimmedBlocker != trimmedBlocked else { throw ReportValidationError.selfReport }

        try await withRetry(maxAttempts: maxRetries, baseDelay: retryBaseDelay) {
            try await self.db
                .collection("users")
                .document(trimmedBlocker)
                .collection("blockedUsers")
                .document(trimmedBlocked)
                .setData(["blockedAt": Timestamp(date: Date())])
        }
    }

    // MARK: - Check Block Status

    func isUserBlocked(blockerUID: String, blockedUID: String) async -> Bool {
        do {
            let doc = try await db
                .collection("users")
                .document(blockerUID)
                .collection("blockedUsers")
                .document(blockedUID)
                .getDocument()
            return doc.exists
        } catch {
            return false
        }
    }

    // MARK: - Retry Helper

    /// Retries an async throwing operation using exponential back-off.
    private func withRetry(
        maxAttempts: Int,
        baseDelay: TimeInterval,
        operation: @escaping () async throws -> Void
    ) async throws {
        var lastError: Error?
        for attempt in 0..<maxAttempts {
            do {
                try await operation()
                return
            } catch {
                lastError = error
                if attempt < maxAttempts - 1 {
                    let delay = baseDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        submissionError = lastError
        throw lastError!
    }
}
