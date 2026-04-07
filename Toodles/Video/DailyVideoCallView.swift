import SwiftUI
import Daily

// TDV-71: Build DailyVideoCallView SwiftUI interface with call controls
// Parent: TDV-41 - Integrate Daily SDK for peer-to-peer video calling

/// Main SwiftUI view for the Daily.co video call interface.
struct DailyVideoCallView: View {
    @StateObject private var viewModel: DailyVideoCallViewModel
    @Environment(\.dismiss) private var dismiss

    let roomURL: URL
    let token: String?

    init(roomURL: URL, token: String? = nil) {
        self.roomURL = roomURL
        self.token = token
        _viewModel = StateObject(wrappedValue: DailyVideoCallViewModel())
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isInCall {
                callView
            } else {
                connectingView
            }

            if viewModel.isShowingError {
                errorOverlay
            }
        }
        .onAppear {
            viewModel.joinCall(url: roomURL, token: token)
        }
        .onDisappear {
            viewModel.leaveCall()
        }
    }

    // MARK: - Subviews

    private var callView: some View {
        VStack(spacing: 0) {
            ZStack {
                if let remoteVideoTrack = viewModel.remoteVideoTrack {
                    VideoView(videoTrack: remoteVideoTrack)
                        .ignoresSafeArea()
                } else {
                    placeholderView(label: "Waiting for participant...")
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if let localVideoTrack = viewModel.localVideoTrack {
                            VideoView(videoTrack: localVideoTrack)
                                .frame(width: 100, height: 150)
                                .cornerRadius(12)
                                .padding()
                        }
                    }
                }
            }

            VideoCallControlsView(
                isMicMuted: viewModel.isMicMuted,
                isCameraOff: viewModel.isCameraOff,
                onToggleMic: { viewModel.toggleMic() },
                onToggleCamera: { viewModel.toggleCamera() },
                onEndCall: {
                    viewModel.leaveCall()
                    dismiss()
                }
            )
            .padding(.bottom, 20)
        }
    }

    private var connectingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            Text("Connecting...")
                .foregroundColor(.white)
                .font(.headline)
        }
    }

    private var errorOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
                .font(.largeTitle)
            Text(viewModel.errorMessage ?? "An error occurred")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Dismiss") {
                viewModel.isShowingError = false
                dismiss()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color.red)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.black.opacity(0.85))
        .cornerRadius(16)
        .padding()
    }

    private func placeholderView(label: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "person.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text(label)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.1))
    }
}
