import SwiftUI

struct SupportView: View {
    @State private var selectedCategory: String = ""
    @State private var subject = ""
    @State private var description = ""
    @State private var showConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            ToodlesHeader(title: "Customer Support")

            ZStack {
                AmbientOrbBackground(intensity: .soft)

                ScrollView {
                    VStack(spacing: 14) {
                        Text("How can we help you?")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)

                        categoryCard(icon: "flag.fill", iconColor: ToodlesTheme.accent, title: "Report User", subtitle: "Report inappropriate behavior or content", category: "report_user")
                        categoryCard(icon: "message.fill", iconColor: ToodlesTheme.bodyTop, title: "App Feedback", subtitle: "Share your thoughts and suggestions", category: "feedback")
                        categoryCard(icon: "wrench.fill", iconColor: ToodlesTheme.bodyTop, title: "Technical Help", subtitle: "Get help with technical issues", category: "tech_help")

                        if !selectedCategory.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                TextField("Subject", text: $subject)
                                    .foregroundStyle(.black)
                                    .tint(.black)
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                TextEditor(text: $description)
                                    .foregroundStyle(.black)
                                    .tint(.black)
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .scrollContentBackground(.hidden)
                                Button("Submit") { submit() }
                                    .buttonStyle(ToodlesPrimaryButtonStyle())
                                    .disabled(subject.isEmpty || description.isEmpty)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .alert("Ticket submitted", isPresented: $showConfirmation) {
            Button("OK", role: .cancel) { reset() }
        }
    }

    private func categoryCard(icon: String, iconColor: Color, title: String, subtitle: String, category: String) -> some View {
        Button {
            selectedCategory = category
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.bold())
                        .foregroundStyle(.black)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                if selectedCategory == category {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ToodlesTheme.accent)
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func submit() {
        guard let uid = AuthManager.shared.currentUID else {
            showConfirmation = true
            return
        }
        FirestoreService.shared.createSupportTicket(
            userId: uid,
            subject: subject,
            description: description,
            category: selectedCategory
        ) { _ in
            DispatchQueue.main.async { showConfirmation = true }
        }
    }

    private func reset() {
        subject = ""
        description = ""
        selectedCategory = ""
    }
}
