import SwiftUI

// TDV-68: Build DailyVideoCallView SwiftUI interface
// Provides the in-call controls overlay: mute, camera toggle, end call

struct VideoCallControlsView: View {
    
    @ObservedObject var viewModel: DailyVideoCallViewModel
    @State private var showEndCallConfirmation = false
    
    var body: some View {
        VStack {
            Spacer()
            
            // Call duration timer
            Text(viewModel.callDurationFormatted)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
                .padding(.bottom, 16)
            
            // Control buttons row
            HStack(spacing: 32) {
                
                // Microphone toggle
                ControlButton(
                    icon: viewModel.isMuted ? "mic.slash.fill" : "mic.fill",
                    label: viewModel.isMuted ? "Unmute" : "Mute",
                    color: viewModel.isMuted ? .red : .white,
                    action: { viewModel.toggleMute() }
                )
                
                // End call button (center, prominent)
                Button(action: { showEndCallConfirmation = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 72, height: 72)
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: .red.opacity(0.5), radius: 8, x: 0, y: 4)
                
                // Camera toggle
                ControlButton(
                    icon: viewModel.isCameraOff ? "video.slash.fill" : "video.fill",
                    label: viewModel.isCameraOff ? "Camera On" : "Camera Off",
                    color: viewModel.isCameraOff ? .red : .white,
                    action: { viewModel.toggleCamera() }
                )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .confirmationDialog("End Call", isPresented: $showEndCallConfirmation, titleVisibility: .visible) {
            Button("End Call", role: .destructive) {
                viewModel.endCall()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to end this call?")
        }
    }
}

// MARK: - Reusable control button component
struct ControlButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}
