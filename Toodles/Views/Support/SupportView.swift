import SwiftUI

struct SupportView: View {
    @State private var selectedCategory: String = ""
    @State private var subject = ""
    @State private var description = ""
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.blue, .cyan.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Text("How can we help you?")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)

                        categoryButton(icon: "flag.fill", title: "Report User", subtitle: "Report inappropriate behavior or content", category: "report_user")
                        categoryButton(icon: "message.fill", title: "App Feedback", subtitle: "Share your thoughts and suggestions", category: "feedback")
                        categoryButton(icon: "wrench.fill", title: "Technical Help", subtitle: "Get help with technical issues", category: "tech_help")

                        if !selectedCategory.isEmpty {
                            TextField("Subject", text: $subject)
                                .padding()
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            TextEditor(text: $description)
                                .frame(height: 120)
                                .padding(8)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            Button("Submit") { submit() }
                                .buttonStyle(ToodlesPrimaryButtonStyle())
                                .disabled(subject.isEmpty || description.isEmpty)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Customer Support")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Ticket submitted", isPresented: $showConfirmation) {
                Button("OK", role: .cancel) { reset() }
            }
        }
    }

    private func categoryButton(icon: String, title: String, subtitle: String, category: String) -> some View {
        Button {
            selectedCategory = category
        } label: {
            HStack {
                Image(systemName: icon).font(.title2).frame(width: 40)
                VStack(alignment: .leading) {
                    Text(title).bold()
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if selectedCategory == category {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.orange)
                }
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.black)
        }
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
