// TDV-41: Integrate Daily SDK for peer-to-peer WebRTC video
// DailyVideoCallView.swift
// Toodles

import SwiftUI

struct DailyVideoCallView: View {
    @StateObject private var viewModel: DailyVideoCallViewModel
    @Environment(\.dismiss) private var dismiss
    let matchId: String
    let roomURL: String

    init(matchId: String, roomURL: String) {
        self.matchId = matchId
        self.roomURL = roomURL
        _viewModel = StateObject(wrappedValue: DailyVideoCallViewModel(matchId: matchId, roomURL: roomURL))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            remoteVideoView
            VStack {
                HStack {
                    Spacer()
                    localVideoView
                        .frame(width: 100, height: 140)
                        .cornerRadius(12)
                        .padding()
                }
                Spacer()
            }
            VStack { Spacer(); callControlsBar }
            if viewModel.callState != .connected { statusOverlay }
        }
        .onAppear { viewModel.joinCall() }
        .onDisappear { viewModel.leaveCall() }
    }

    private var remoteVideoView: some View {
        Group {
            if viewModel.remoteParticipants.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80)).foregroundColor(.gray)
                    Text("Waiting for match...").foregroundColor(.white).font(.headline)
                }
            } else {
                Rectangle().fill(Color.gray.opacity(0.3))
                    .overlay(Text(viewModel.remoteParticipants.first?.userName ?? "").foregroundColor(.white))
            }
        }
    }

    private var localVideoView: some View {
        Rectangle().fill(Color.gray.opacity(0.5))
            .overlay(Text("You").foregroundColor(.white).font(.caption))
    }

    private var callControlsBar: some View {
        HStack(spacing: 40) {
            Button(action: { viewModel.toggleMic() }) {
                Image(systemName: viewModel.isMicEnabled ? "mic.fill" : "mic.slash.fill")
                    .font(.title2).foregroundColor(.white)
                    .frame(width: 56, height: 56).background(Color.white.opacity(0.2)).clipShape(Circle())
            }
            Button(action: { viewModel.endCall(); dismiss() }) {
                Image(systemName: "phone.down.fill")
                    .font(.title2).foregroundColor(.white)
                    .frame(width: 64, height: 64).background(Color.red).clipShape(Circle())
            }
            Button(action: { viewModel.toggleCamera() }) {
                Image(systemName: viewModel.isCameraEnabled ? "video.fill" : "video.slash.fill")
                    .font(.title2).foregroundColor(.white)
                    .frame(width: 56, height: 56).background(Color.white.opacity(0.2)).clipShape(Circle())
            }
        }
        .padding(.bottom, 48)
    }

    private var statusOverlay: some View {
        VStack(spacing: 12) {
            ProgressView().tint(.white).scaleEffect(1.5)
            Text(viewModel.statusText).foregroundColor(.white).font(.subheadline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.6))
    }
}
