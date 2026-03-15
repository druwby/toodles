import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var status = "Ready to test"

    var body: some View {
        VStack(spacing: 20) {
            Text(status)
                .padding()

            Button("Write Test Data") {
                writeTestData()
            }

            Button("Read Test Data") {
                readTestData()
            }
        }
    }

    func writeTestData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            status = "Error: Not signed in"
            return
        }
        let db = Firestore.firestore()

        db.collection("users").document(uid).setData([
            "name": "Vince",
            "age": 25,
            "likes": ["coding", "gaming"]
        ]) { error in
            if let error = error {
                status = "Error: \(error.localizedDescription)"
            } else {
                status = "✅ Data written successfully!"
            }
        }
    }

    func readTestData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            status = "Error: Not signed in"
            return
        }
        let db = Firestore.firestore()

        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                status = "✅ Read: \(data?["name"] ?? "unknown")"
            } else {
                status = "❌ Document not found"
            }
        }
    }
}
