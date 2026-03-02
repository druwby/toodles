// SafetyContent.swift
// Toodles
//
// TDV-53: Integrate contextual safety UX throughout navigation
// Assignee: Danny Shtansky

import Foundation

// MARK: - Safety Content Type

/// Defines the category of safety content to display contextually
enum SafetyContentType: String, CaseIterable, Codable {
    case tip        = "tip"
    case warning    = "warning"
    case resource   = "resource"
    case emergency  = "emergency"
}

// MARK: - Navigation Context

/// Represents the navigation screen/context where safety content is shown
enum NavigationContext: String, CaseIterable, Codable {
    case onboarding         = "onboarding"
    case matching           = "matching"
    case videoCall          = "video_call"
    case profile            = "profile"
    case settings           = "settings"
    case reportUser         = "report_user"
    case blockUser          = "block_user"
    case postCall           = "post_call"
    case chat               = "chat"
    case helpCenter         = "help_center"
}

// MARK: - Safety Item Model

/// A single safety content item with contextual metadata
struct SafetyItem: Identifiable, Codable, Equatable {
    let id: UUID
    let type: SafetyContentType
    let context: NavigationContext
    let title: String
    let body: String
    let actionLabel: String?
    let actionURL: URL?
    let priority: Int          // 1 = highest priority
    let isDismissible: Bool
    let showOnce: Bool         // if true, only show once per session

    init(
        id: UUID = UUID(),
        type: SafetyContentType,
        context: NavigationContext,
        title: String,
        body: String,
        actionLabel: String? = nil,
        actionURL: URL? = nil,
        priority: Int = 3,
        isDismissible: Bool = true,
        showOnce: Bool = false
    ) {
        self.id = id
        self.type = type
        self.context = context
        self.title = title
        self.body = body
        self.actionLabel = actionLabel
        self.actionURL = actionURL
        self.priority = priority
        self.isDismissible = isDismissible
        self.showOnce = showOnce
    }
}

// MARK: - Safety Resource

/// An external help or emergency resource
struct SafetyResource: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let phoneNumber: String?
    let websiteURL: URL?
    let isEmergency: Bool
    let category: SafetyResourceCategory

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        phoneNumber: String? = nil,
        websiteURL: URL? = nil,
        isEmergency: Bool = false,
        category: SafetyResourceCategory
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.phoneNumber = phoneNumber
        self.websiteURL = websiteURL
        self.isEmergency = isEmergency
        self.category = category
    }
}

enum SafetyResourceCategory: String, CaseIterable, Codable {
    case crisis         = "crisis"
    case harassment     = "harassment"
    case mentalHealth   = "mental_health"
    case localSupport   = "local_support"
    case inApp          = "in_app"
}

// MARK: - Safety Banner State

/// Represents the display state of a contextual safety banner
struct SafetyBannerState: Equatable {
    var isVisible: Bool
    var item: SafetyItem?
    var isDismissed: Bool

    static let hidden = SafetyBannerState(isVisible: false, item: nil, isDismissed: false)
}
