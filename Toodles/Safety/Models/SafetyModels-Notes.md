# TDV-57: SafetyContent Models and SafetyContentProvider Service

**Subtask of:** TDV-53 — Integrate contextual safety UX throughout navigation  
**Assignee:** Danny Shtansky  

## Overview

This subtask implements the data layer for the contextual safety UX feature — the models that define what safety content looks like, and the provider service that supplies the right content for each screen context.

## SafetyContent.swift — Data Models

The following Swift structs and enums define the safety content domain:

| Type | Purpose |
|------|---------|
| `SafetyContext` | Enum of all screen contexts (`.matching`, `.videoCall`, `.profile`, `.messaging`, `.general`) |
| `SafetyTip` | A dismissible tip shown inline on a screen (id, title, body, context, icon) |
| `SafetyWarning` | A higher-priority warning requiring acknowledgment (id, title, body, severity) |
| `SafetyResource` | An external help resource (id, title, url, category: hotline/article/guide) |
| `SafetyContent` | Aggregate container holding tips, warnings, and resources for a given context |

All models conform to `Identifiable`, `Codable`, and `Equatable` for SwiftUI list rendering and persistence.

## SafetyContentProvider.swift — Content Service

A singleton service (`SafetyContentProvider.shared`) that returns the appropriate `SafetyContent` for any given `SafetyContext`. Content includes:

- **Matching context:** Tips on recognizing red flags, resource link to NCADV
- **Video call context:** Warning about sharing personal information, emergency exit instructions
- **Profile context:** Tips on photo safety and reverse image search awareness
- **Messaging context:** Guidance on keeping communication in-app before meeting
- **General context:** National hotlines (NDVH: 1-800-799-7233, Crisis Text Line: Text HOME to 741741)

All copy is static and bundled with the app — no network request required for safety content.
