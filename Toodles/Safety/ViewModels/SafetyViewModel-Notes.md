# TDV-58: SafetyViewModel and SafetySessionManager

**Subtask of:** TDV-53 — Integrate contextual safety UX throughout navigation  
**Assignee:** Danny Shtansky  

## SafetyViewModel.swift

`SafetyViewModel` is an `ObservableObject` that acts as the single source of truth for safety UI state across all navigation screens.

### Published Properties

| Property | Type | Purpose |
|----------|------|---------|
| `currentContent` | `SafetyContent?` | The active safety content for the current screen |
| `activeBanner` | `SafetyTip?` | The tip currently shown in the inline banner |
| `showSheet` | `Bool` | Controls presentation of the full safety detail sheet |
| `showResources` | `Bool` | Controls presentation of the resources browser |
| `pendingWarning` | `SafetyWarning?` | A warning requiring user acknowledgment |

### Key Methods

- `loadContext(_ context: SafetyContext)` — Called when a screen appears; loads appropriate content and determines if a banner should show based on session state
- `dismissBanner()` — Marks the current tip as dismissed in `SafetySessionManager` and clears `activeBanner`
- `acknowledgeWarning()` — Clears `pendingWarning` and records acknowledgment
- `openResources()` — Sets `showResources = true` to present the resources sheet

## SafetySessionManager.swift

A lightweight persistence layer using `UserDefaults` to track which safety banners a user has already dismissed within a session.

### Behavior

- Dismissed tip IDs are stored in `UserDefaults` under the key `safety_dismissed_tips`
- On app relaunch, dismissed tips are remembered so users are not repeatedly shown the same content
- A `resetSession()` method clears all dismissed state (used for testing or after a long inactivity period)
- The manager is injected into `SafetyViewModel` as a dependency for testability
