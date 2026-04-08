import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.fill")
                .font(.system(size: 72))
                .foregroundStyle(.orange)
            Text("Toodles")
                .font(.largeTitle.bold())
            Text("Scaffold is alive.")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
