import SwiftUI
import AVFoundation

struct MockVideoCallView: View {
    let matchName: String
    var onEnd: () -> Void

    @State private var remaining: Int = 60
    @State private var muted: Bool = false
    @State private var useFrontCamera: Bool = true
    @State private var showFeedback = false

    var body: some View {
        ZStack {
            CameraPreview(useFrontCamera: $useFrontCamera)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Text(matchName)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Spacer()
                    Text("0:\(String(format: "%02d", remaining))")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)
                .padding(.top, 50)

                Spacer()

                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Circle().fill(.gray.opacity(0.7)).frame(width: 48, height: 48)
                            .overlay(Image(systemName: "person.fill").foregroundStyle(.white))
                        Text(matchName).font(.caption2).foregroundStyle(.white)
                    }
                    .padding(12)
                    .background(.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()

                HStack(spacing: 40) {
                    Button { muted.toggle() } label: {
                        Image(systemName: muted ? "mic.slash.fill" : "mic.fill")
                            .font(.title2)
                            .frame(width: 64, height: 64)
                            .background(muted ? .red : .black.opacity(0.5))
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                    Button { hangup() } label: {
                        Image(systemName: "phone.down.fill")
                            .font(.title)
                            .frame(width: 72, height: 72)
                            .background(.red)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                    Button { useFrontCamera.toggle() } label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.title2)
                            .frame(width: 64, height: 64)
                            .background(.black.opacity(0.5))
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if remaining > 0 {
                remaining -= 1
                if remaining == 0 { hangup() }
            }
        }
        .fullScreenCover(isPresented: $showFeedback) {
            PostSessionFeedbackView(matchName: matchName, onDone: { onEnd() })
        }
    }

    private func hangup() {
        showFeedback = true
    }
}

// MARK: - AVFoundation camera preview (UIViewRepresentable bridge)

struct CameraPreview: UIViewRepresentable {
    @Binding var useFrontCamera: Bool

    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView()
        v.configure(front: useFrontCamera)
        return v
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.configure(front: useFrontCamera)
    }
}

final class PreviewView: UIView {
    private var session: AVCaptureSession?
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    func configure(front: Bool) {
        // Tear down any existing session before re-configuring
        session?.stopRunning()
        let newSession = AVCaptureSession()
        newSession.sessionPreset = .medium

        let position: AVCaptureDevice.Position = front ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            // On the iOS Simulator without a passthrough camera this will fail gracefully;
            // the preview layer shows the previous session or stays black — still usable for demo.
            return
        }
        newSession.beginConfiguration()
        if newSession.canAddInput(input) { newSession.addInput(input) }
        newSession.commitConfiguration()

        if let layer = self.layer as? AVCaptureVideoPreviewLayer {
            layer.session = newSession
            layer.videoGravity = .resizeAspectFill
        }

        DispatchQueue.global(qos: .userInitiated).async {
            newSession.startRunning()
        }
        self.session = newSession
    }
}
