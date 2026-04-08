// LanguageFilterService.swift
// Toodles
// TDV-49: Integrate automated text-based language filtering

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

enum FilterResult {
    case clean
    case flagged(reason: String)
    case blocked(reason: String)
}

enum FilterSeverity: String, Codable {
    case low
    case medium
    case high
    case critical
}

struct FilterViolation: Codable {
    let userUID: String
    let messageText: String
    let severity: FilterSeverity
    let reason: String
    let timestamp: Date
    let sessionID: String
}

@MainActor
class LanguageFilterService: ObservableObject {
    @Published var isFiltering: Bool = false
    @Published var violationCount: Int = 0

    private let db = Firestore.firestore()
    private let violationsCollection = "filter_violations"
    private var currentUserUID: String? { Auth.auth().currentUser?.uid }

    private let criticalPatterns: [String] = [
        "\b(hate|kill|harm|threat)\b"
    ]
    private let highPatterns: [String] = [
        "\b(slur|abuse|harass)\b"
    ]
    private let mediumPatterns: [String] = [
        "\b(spam|scam|phish)\b"
    ]

    func evaluate(message: String) -> FilterResult {
        let lowercased = message.lowercased()
        for pattern in criticalPatterns {
            if matches(text: lowercased, pattern: pattern) {
                return .blocked(reason: "Critical language policy violation detected.")
            }
        }
        for pattern in highPatterns {
            if matches(text: lowercased, pattern: pattern) {
                return .blocked(reason: "High-severity language policy violation detected.")
            }
        }
        for pattern in mediumPatterns {
            if matches(text: lowercased, pattern: pattern) {
                return .flagged(reason: "Message flagged for review.")
            }
        }
        return .clean
    }

    func evaluateAndLog(message: String, sessionID: String) async -> FilterResult {
        let result = evaluate(message: message)
        switch result {
        case .clean: break
        case .flagged(let reason):
            await logViolation(message: message, severity: .medium, reason: reason, sessionID: sessionID)
        case .blocked(let reason):
            await logViolation(message: message, severity: .critical, reason: reason, sessionID: sessionID)
        }
        return result
    }

    private func matches(text: String, pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return false }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }

    private func logViolation(message: String, severity: FilterSeverity, reason: String, sessionID: String) async {
        guard let uid = currentUserUID else { return }
        let data: [String: Any] = [
            "userUID": uid,
            "messageText": message,
            "severity": severity.rawValue,
            "reason": reason,
            "timestamp": FieldValue.serverTimestamp(),
            "sessionID": sessionID
        ]
        try? await db.collection(violationsCollection).addDocument(data: data)
        violationCount += 1
    }

    func fetchViolationCount() async {
        guard let uid = currentUserUID else { return }
        isFiltering = true
        defer { isFiltering = false }
        do {
            let snapshot = try await db.collection(violationsCollection)
                .whereField("userUID", isEqualTo: uid)
                .getDocuments()
            violationCount = snapshot.documents.count
        } catch {
            print("Error fetching violations: \(error)")
        }
    }
}
