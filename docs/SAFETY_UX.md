# Contextual Safety UX — Architecture & Integration Guide

**JIRA Task:** TDV-53  
**Feature:** Integrate contextual safety UX throughout navigation  
**Assignee:** Danny Shtansky  
**Sprint:** Sprint 1 (Feb 15 – Mar 1, 2026)

---

## Overview

The Contextual Safety UX system integrates safety tips, warnings, and help resources throughout the Toodles navigation flow. Safety information is surfaced at the right moment — when users are most likely to benefit from it — rather than buried in a settings menu.

The system is designed around three principles:

1. **Contextual relevance** — each screen shows safety content specific to the actions being taken on that screen.
2. **Non-intrusive delivery** — safety banners are dismissible and respect user preferences via session state persistence.
3. **Immediate access** — a persistent shield button in the navigation bar provides one-tap access to the full Safety Center from any screen.

---

## Architecture

```
SafetyContentProvider       (static content database)
        │
        ▼
SafetySessionManager        (session/persistence state)
        │
        ▼
SafetyViewModel             (per-screen state driver)
        │
        ├── SafetyBannerView         (inline contextual banner)
        ├── SafetySheetView          (full Safety Center sheet)
        ├── SafetyResourcesView      (resources browser)
        ├── SafetyNavigationModifier (.withSafetyUX() modifier)
        └── SafetyOverlayView        (floating overlay for video calls)
```

### Component Responsibilities

| Component | Responsibility |
|---|---|
| `SafetyContentProvider` | Stores all safety tips, warnings, and resources keyed by `NavigationContext` |
| `SafetySessionManager` | Tracks dismissed and shown-once items; persists state via `UserDefaults` |
| `SafetyViewModel` | Drives UI for a specific screen; filters items by session state |
| `SafetyBannerView` | Renders a single inline safety item with dismiss and action buttons |
| `SafetySheetView` | Full-screen safety center with all contextual tips and quick actions |
| `SafetyResourcesView` | Browsable list of all safety resources grouped by category |
| `SafetyNavigationModifier` | View modifier (`.withSafetyUX()`) that injects banner + shield button |
| `SafetyOverlayView` | Floating action button cluster for full-screen contexts (video calls) |

---

## Navigation Context Coverage

| Screen | Context | Content Type |
|---|---|---|
| Onboarding | `.onboarding` | Tips (show-once) |
| Matching / Browse | `.matching` | Tips + Warnings |
| Video Call | `.videoCall` | Tips + Warnings + Resources (overlay) |
| Profile | `.profile` | Tips |
| Settings | `.settings` | Resources |
| Report User | `.reportUser` | Resources + Emergency |
| Block User | `.blockUser` | Resources |
| Post-Call | `.postCall` | Tips + Resources |
| Chat | `.chat` | Warnings |
| Help Center | `.helpCenter` | Resources |

---

## Integration

### Standard screens (with navigation bar)

```swift
struct MatchingView: View {
    var body: some View {
        List { ... }
            .withSafetyUX(context: .matching)
    }
}
```

### Video call screen (full-screen, no navigation bar)

```swift
struct VideoCallView: View {
    var body: some View {
        DailyVideoCallContainer()
            .withVideoCallSafetyOverlay()
            .ignoresSafeArea()
    }
}
```

---

## Safety Content Types

| Type | Icon | Color | Use Case |
|---|---|---|---|
| `.tip` | 💡 lightbulb | Blue | Proactive safety advice |
| `.warning` | ⚠️ triangle | Orange | Scam/risk alerts |
| `.resource` | 🛡 shield | Green | Help resources |
| `.emergency` | 🆘 SOS | Red | Immediate danger situations |

---

## Session State Logic

- **Dismissible items** — users can dismiss banners; dismissed state is persisted across app launches via `UserDefaults`.
- **Show-once items** — items with `showOnce: true` are shown only once per install (e.g., onboarding safety intro).
- **Priority ordering** — items are sorted by `priority` (1 = highest); the highest-priority undismissed item is shown as the active banner.

---

## Safety Resources Included

| Resource | Category | Emergency |
|---|---|---|
| National Domestic Violence Hotline | Crisis | Yes |
| Crisis Text Line (741741) | Crisis | Yes |
| RAINN Sexual Assault Hotline | Crisis | Yes |
| Cyber Civil Rights Initiative | Harassment | No |
| NAMI Mental Health Helpline | Mental Health | No |
| Toodles Safety Center | In-App | No |
| Internet Crimes Against Children Task Force | Harassment | No |

---

## Files

```
Toodles/Safety/
├── Models/
│   └── SafetyContent.swift          (SafetyItem, SafetyResource, enums)
├── Services/
│   ├── SafetyContentProvider.swift  (all safety content database)
│   └── SafetySessionManager.swift   (session state & persistence)
├── ViewModels/
│   └── SafetyViewModel.swift        (per-screen UI state driver)
├── Views/
│   ├── SafetyBannerView.swift       (inline contextual banner)
│   ├── SafetySheetView.swift        (full Safety Center sheet)
│   ├── SafetyResourcesView.swift    (resources browser)
│   ├── SafetyNavigationModifier.swift (.withSafetyUX() modifier)
│   └── SafetyOverlayView.swift      (video call floating overlay)
└── SafetyIntegrationGuide.swift     (developer integration reference)
```
