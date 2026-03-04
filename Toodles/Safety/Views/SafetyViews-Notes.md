# TDV-59: SwiftUI Safety Views and Navigation Modifier

**Subtask of:** TDV-53 — Integrate contextual safety UX throughout navigation  
**Assignee:** Danny Shtansky  

## Views Implemented

### SafetyBannerView.swift
An inline, dismissible banner that appears at the top of any screen. It displays a `SafetyTip` with an icon, title, and body text. A dismiss button calls `viewModel.dismissBanner()`. The banner animates in/out using SwiftUI's `.transition(.move(edge: .top).combined(with: .opacity))`.

### SafetySheetView.swift
A full-screen sheet presenting detailed safety information for the current context. Shows the active `SafetyWarning` (if any) with an acknowledgment button, followed by a list of `SafetyResource` items with tappable links that open in `SafariView`.

### SafetyResourcesView.swift
A browseable list of all safety resources organized by category (Hotlines, Articles, Guides). Accessible from any screen via the safety button. Each resource row shows the title, category badge, and an external link icon. Tapping opens the URL in an in-app browser.

### SafetyOverlayView.swift
A floating action button rendered on top of the video call screen. Displays a shield icon in the bottom-right corner. Tapping it presents `SafetySheetView` as a sheet without interrupting the video call. Designed to be unobtrusive but always accessible during a live session.

### SafetyNavigationModifier.swift
A SwiftUI `ViewModifier` that injects the full safety UX into any screen with a single line:

```swift
.modifier(SafetyNavigationModifier(context: .videoCall))
// or using the convenience extension:
.safetyContext(.videoCall)
```

The modifier:
1. Creates and owns a `SafetyViewModel` instance
2. Calls `viewModel.loadContext(context)` on `.onAppear`
3. Overlays `SafetyBannerView` at the top of the view
4. Attaches `.sheet` modifiers for `SafetySheetView` and `SafetyResourcesView`
5. Injects the view model into the environment for child views
