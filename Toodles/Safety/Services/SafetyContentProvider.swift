// SafetyContentProvider.swift
// Toodles
//
// TDV-53: Integrate contextual safety UX throughout navigation
// Assignee: Danny Shtansky

import Foundation

// MARK: - Safety Content Provider

/// Provides contextual safety tips, warnings, and help resources
/// for each navigation screen in the Toodles app.
final class SafetyContentProvider {

    static let shared = SafetyContentProvider()
    private init() {}

    // MARK: - Contextual Safety Items

    /// Returns safety items relevant to the given navigation context, sorted by priority
    func safetyItems(for context: NavigationContext) -> [SafetyItem] {
        return allSafetyItems
            .filter { $0.context == context }
            .sorted { $0.priority < $1.priority }
    }

    /// Returns the highest-priority safety item for a given context
    func primarySafetyItem(for context: NavigationContext) -> SafetyItem? {
        return safetyItems(for: context).first
    }

    // MARK: - All Safety Resources

    var allResources: [SafetyResource] {
        return [
            SafetyResource(
                name: "National Domestic Violence Hotline",
                description: "24/7 confidential support for those affected by domestic violence.",
                phoneNumber: "1-800-799-7233",
                websiteURL: URL(string: "https://www.thehotline.org"),
                isEmergency: true,
                category: .crisis
            ),
            SafetyResource(
                name: "Crisis Text Line",
                description: "Text HOME to 741741 to connect with a trained crisis counselor.",
                phoneNumber: "741741",
                websiteURL: URL(string: "https://www.crisistextline.org"),
                isEmergency: true,
                category: .crisis
            ),
            SafetyResource(
                name: "RAINN Sexual Assault Hotline",
                description: "Support for survivors of sexual violence.",
                phoneNumber: "1-800-656-4673",
                websiteURL: URL(string: "https://www.rainn.org"),
                isEmergency: true,
                category: .crisis
            ),
            SafetyResource(
                name: "Cyber Civil Rights Initiative",
                description: "Support for victims of non-consensual intimate image sharing.",
                phoneNumber: nil,
                websiteURL: URL(string: "https://cybercivilrights.org"),
                isEmergency: false,
                category: .harassment
            ),
            SafetyResource(
                name: "National Alliance on Mental Illness (NAMI)",
                description: "Mental health support, education, and advocacy.",
                phoneNumber: "1-800-950-6264",
                websiteURL: URL(string: "https://www.nami.org"),
                isEmergency: false,
                category: .mentalHealth
            ),
            SafetyResource(
                name: "Toodles Safety Center",
                description: "In-app safety tips, reporting tools, and community guidelines.",
                phoneNumber: nil,
                websiteURL: URL(string: "https://toodles.app/safety"),
                isEmergency: false,
                category: .inApp
            ),
            SafetyResource(
                name: "Internet Crimes Against Children Task Force",
                description: "Report online exploitation and get support.",
                phoneNumber: "1-800-843-5678",
                websiteURL: URL(string: "https://www.icactaskforce.org"),
                isEmergency: false,
                category: .harassment
            )
        ]
    }

    // MARK: - Private: All Safety Items

    private var allSafetyItems: [SafetyItem] {
        return onboardingItems
            + matchingItems
            + videoCallItems
            + profileItems
            + settingsItems
            + reportItems
            + postCallItems
            + chatItems
    }

    // MARK: Onboarding Safety Items

    private var onboardingItems: [SafetyItem] {
        [
            SafetyItem(
                type: .tip,
                context: .onboarding,
                title: "Your Safety Comes First",
                body: "Toodles is designed with your safety in mind. Review our community guidelines and safety features before you start connecting.",
                actionLabel: "View Safety Center",
                actionURL: URL(string: "https://toodles.app/safety"),
                priority: 1,
                isDismissible: true,
                showOnce: true
            ),
            SafetyItem(
                type: .tip,
                context: .onboarding,
                title: "Protect Your Personal Information",
                body: "Never share your home address, workplace, or financial information with matches. Keep conversations on Toodles until you feel comfortable.",
                priority: 2,
                isDismissible: true,
                showOnce: true
            ),
            SafetyItem(
                type: .tip,
                context: .onboarding,
                title: "Trust Your Instincts",
                body: "If something feels off, it probably is. You can block or report any user at any time — no explanation needed.",
                priority: 3,
                isDismissible: true,
                showOnce: true
            )
        ]
    }

    // MARK: Matching Safety Items

    private var matchingItems: [SafetyItem] {
        [
            SafetyItem(
                type: .tip,
                context: .matching,
                title: "Spotting Fake Profiles",
                body: "Watch for profiles with very few photos, vague bios, or who quickly ask to move off the app. Report suspicious accounts.",
                actionLabel: "Learn More",
                actionURL: URL(string: "https://toodles.app/safety/fake-profiles"),
                priority: 2,
                isDismissible: true,
                showOnce: false
            ),
            SafetyItem(
                type: .warning,
                context: .matching,
                title: "Never Send Money",
                body: "Toodles will never ask you to send money to a match. Requests for financial help are a major red flag — report them immediately.",
                priority: 1,
                isDismissible: true,
                showOnce: false
            )
        ]
    }

    // MARK: Video Call Safety Items

    private var videoCallItems: [SafetyItem] {
        [
            SafetyItem(
                type: .tip,
                context: .videoCall,
                title: "Video Call Safety Tips",
                body: "Make sure your background doesn't reveal your location. Avoid showing identifying information like mail, street signs, or landmarks.",
                priority: 1,
                isDismissible: true,
                showOnce: true
            ),
            SafetyItem(
                type: .warning,
                context: .videoCall,
                title: "Screen Recording Warning",
                body: "Recording or screenshotting video calls without consent is a violation of our community guidelines and may be illegal in your jurisdiction.",
                priority: 1,
                isDismissible: false,
                showOnce: true
            ),
            SafetyItem(
                type: .resource,
                context: .videoCall,
                title: "Need Help During a Call?",
                body: "Tap the shield icon at any time to access safety resources, end the call, or report inappropriate behavior.",
                priority: 2,
                isDismissible: true,
                showOnce: true
            )
        ]
    }

    // MARK: Profile Safety Items

    private var profileItems: [SafetyItem] {
        [
            SafetyItem(
                type: .tip,
                context: .profile,
                title: "Profile Privacy Tips",
                body: "Avoid including your last name, employer, or neighborhood in your profile. Use photos that don't reveal your home or workplace.",
                priority: 2,
                isDismissible: true,
                showOnce: false
            )
        ]
    }

    // MARK: Settings Safety Items

    private var settingsItems: [SafetyItem] {
        [
            SafetyItem(
                type: .resource,
                context: .settings,
                title: "Safety & Privacy Controls",
                body: "Manage who can see your profile, control location sharing, and set up two-factor authentication for added security.",
                actionLabel: "Open Safety Settings",
                priority: 1,
                isDismissible: true,
                showOnce: false
            )
        ]
    }

    // MARK: Report User Safety Items

    private var reportItems: [SafetyItem] {
        [
            SafetyItem(
                type: .resource,
                context: .reportUser,
                title: "You're Doing the Right Thing",
                body: "Reporting helps keep Toodles safe for everyone. All reports are reviewed by our Trust & Safety team within 24 hours.",
                priority: 1,
                isDismissible: false,
                showOnce: false
            ),
            SafetyItem(
                type: .emergency,
                context: .reportUser,
                title: "In Immediate Danger?",
                body: "If you are in immediate danger, please call 911 or your local emergency services. Toodles' safety resources are also available below.",
                actionLabel: "View Emergency Resources",
                priority: 1,
                isDismissible: false,
                showOnce: false
            )
        ]
    }

    // MARK: Post-Call Safety Items

    private var postCallItems: [SafetyItem] {
        [
            SafetyItem(
                type: .tip,
                context: .postCall,
                title: "How Was Your Experience?",
                body: "Your feedback helps us improve safety. If anything made you uncomfortable, you can report it now — even after the call has ended.",
                actionLabel: "Report an Issue",
                priority: 2,
                isDismissible: true,
                showOnce: false
            ),
            SafetyItem(
                type: .resource,
                context: .postCall,
                title: "Need to Talk to Someone?",
                body: "If your call left you feeling distressed, free support resources are available 24/7.",
                actionLabel: "View Resources",
                priority: 1,
                isDismissible: true,
                showOnce: false
            )
        ]
    }

    // MARK: Chat Safety Items

    private var chatItems: [SafetyItem] {
        [
            SafetyItem(
                type: .warning,
                context: .chat,
                title: "Keep Conversations on Toodles",
                body: "For your safety, avoid sharing personal contact information or moving to external platforms before you're ready.",
                priority: 2,
                isDismissible: true,
                showOnce: true
            )
        ]
    }
}
