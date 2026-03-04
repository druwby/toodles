import SwiftUI

/// The core "Connect" tab — houses the Start Chatting button.
/// TODO (TDV-30): Wire up real video session once Daily SDK is integrated.
struct ConnectView: View {
    @StateObject private var viewModel = ConnectViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                Group {
                    switch viewModel.state {
                    case .idle:
                        Text("Ready to meet someone new?")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    case .searching:
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Finding a match…")
                                .foregroundStyle(.secondary)
                        }
                    case .connected:
                        Text("Connected! 🎉")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .animation(.easeInOut, value: viewModel.state)

                Spacer()

                Button {
                    viewModel.startChat()
                } label: {
                    Label("Start Chatting", systemImage: "video.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.state == .idle ? Color.pink : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(viewModel.state != .idle)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
            .navigationTitle("Toodles")
        }
    }
}

#Preview {
    ConnectView()
}
