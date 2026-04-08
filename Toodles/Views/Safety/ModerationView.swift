// ModerationView.swift
// Toodles
//
// TDV-75: Create ModerationView and BlockUserView with SwiftUI

import SwiftUI

// MARK: - Report User View

struct ReportUserView: View {
    let reportedUID: String
    let reportedName: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var reportingService = ReportingService.shared
    @State private var selectedReason: ReportReason = .inappropriateContent
    @State private var description: String = ""
    @State private var showConfirmation = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reason for Report")) {
                    Picker("Reason", selection: $selectedReason) {
                        ForEach(ReportReason.allCases, id: \.self) { reason in
                            Text(reason.displayName).tag(reason)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section(header: Text("Additional Details (Optional)")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .placeholder(when: description.isEmpty) {
                            Text("Describe the issue...")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Report \(reportedName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(reportingService.isSubmitting)
                }
            }
            .alert("Report Submitted", isPresented: $showConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("Thank you for helping keep Toodles safe. We will review your report shortly.")
            }
        }
    }

    private func submitReport() {
        guard let currentUID = AuthManager.shared.currentUID else { return }
        Task {
            do {
                try await reportingService.submitReport(
                    reporterUID: currentUID,
                    reportedUID: reportedUID,
                    reason: selectedReason,
                    description: description
                )
                showConfirmation = true
            } catch {
                errorMessage = "Failed to submit report. Please try again."
            }
        }
    }
}

// MARK: - Block User View

struct BlockUserView: View {
    let blockedUID: String
    let blockedName: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var reportingService = ReportingService.shared
    @State private var isBlocking = false
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "person.slash.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.red)
                    .padding(.top, 40)

                Text("Block \(blockedName)?")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 12) {
                    BlockInfoRow(icon: "eye.slash", text: "\(blockedName) won't be able to see your profile")
                    BlockInfoRow(icon: "message.slash", text: "You won't receive messages from \(blockedName)")
                    BlockInfoRow(icon: "video.slash", text: "You won't be matched with \(blockedName)")
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: blockUser) {
                        if isBlocking {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Block \(blockedName)")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(isBlocking)

                    Button("Cancel") { dismiss() }
                        .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
            .alert("User Blocked", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("\(blockedName) has been blocked successfully.")
            }
        }
    }

    private func blockUser() {
        guard let currentUID = AuthManager.shared.currentUID else { return }
        isBlocking = true
        Task {
            do {
                try await reportingService.blockUser(blockerUID: currentUID, blockedUID: blockedUID)
                showSuccess = true
            } catch {
                isBlocking = false
            }
        }
    }
}

// MARK: - Supporting Views

struct BlockInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - ReportReason Display Extension

extension ReportReason {
    var displayName: String {
        switch self {
        case .inappropriateContent: return "Inappropriate Content"
        case .harassment:           return "Harassment or Bullying"
        case .fakeProfile:          return "Fake Profile"
        case .spam:                 return "Spam"
        case .other:                return "Other"
        }
    }
}

// MARK: - Placeholder View Modifier

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .topLeading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
