import SwiftUI
import AVFoundation
import Combine
import Foundation
import AVKit


class AudioPlaybackManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    
    func playRecording(url: URL) {
        guard !isPlaying else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play the recording: \(error.localizedDescription)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}

struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ContentView: View {
    @State private var audioRecorder: AVAudioRecorder?
    @State private var isRecording = false
    @State private var showAlert = false
    @State private var buttonScale: CGFloat = 1.0
    @StateObject private var playbackManager = AudioPlaybackManager()
    @State private var timerSubscription: AnyCancellable?
    @State private var showSuccessAlert = false
    @State private var isConnectedToDjangoBackend = false


    var body: some View {
        ZStack {
            Color(red: 21/255, green: 32/255, blue: 43/255) // ChatGPT Dark Mode Background Color
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                VStack {
                    Button(action: {
                        if self.isRecording {
                            self.stopRecording()
                        } else {
                            self.startRecording()
                        }
                    }) {
                        Text(isRecording ? "Stop" : "Record")
                            .frame(width: 120, height: 120)
                            .foregroundColor(Color.white)
                            .background(Color(red: 235/255, green: 64/255, blue: 52/255)) // Complementary shade of red
                            .clipShape(Circle())
                    }
                    .scaleEffect(buttonScale)
                    .buttonStyle(PressedButtonStyle()) // Add this line
                }
                Spacer()
                HStack {
                    Button(action: {
                        if self.playbackManager.isPlaying {
                            self.stopPlayback()
                        } else {
                            self.playRecording()
                        }
                    }) {
                        Text(playbackManager.isPlaying ? "Stop Playback" : "Play Recording")
                            .padding()
                            .foregroundColor(Color.white)
                            .background(Color(red: 88/255, green: 86/255, blue: 214/255)) // Purple color
                            .cornerRadius(10)
                    }
                    .disabled(isRecording)
                    .buttonStyle(PressedButtonStyle()) // Add this line

                    Button(action: {
                        self.uploadRecording()
                    }) {
                        Text("Upload Recording")
                            .padding()
                            .foregroundColor(Color.white)
                            .background(Color(red: 30/255, green: 144/255, blue: 255/255)) // Light Blue
                            .cornerRadius(10)
                    }
                    .disabled(isRecording || playbackManager.isPlaying)
                    .buttonStyle(PressedButtonStyle()) // Add this line
                }
            }
        }
        .alert(isPresented: $showSuccessAlert) {
            Alert(
                title: Text("Success"),
                message: Text("Your recording has been successfully uploaded."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func startRecording() {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentPath.appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.isMeteringEnabled = true
        } catch {
            print("Failed to set up the audio recorder: \(error.localizedDescription)")
        }
        audioRecorder?.record()
        isRecording = true
        startTimer()
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        timerSubscription?.cancel()
        timerSubscription = nil
        
        showAlert = true
    }
    
    func startTimer() {
        timerSubscription = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.updateButtonScale()
            }
    }
    
    func updateButtonScale() {
        guard let recorder = audioRecorder, isRecording else { return }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let level = meterLevel(forPower: power)
        withAnimation(.linear(duration: 0.1)) {
            buttonScale = 0.8 + (level * 1.5) // Increase the multiplier to make the animation more dramatic
        }
    }

    func meterLevel(forPower power: Float) -> CGFloat {
        return CGFloat(min(max(0, (power + 160) / 160), 1))
    }
    
    func playRecording() {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentPath.appendingPathComponent("recording.m4a")
        playbackManager.playRecording(url: audioURL)
    }
    
    func stopPlayback() {
        playbackManager.stopPlayback()
    }
    
    func uploadRecording() {
        guard let audioRecorder = audioRecorder else { return }
            let audioData = try? Data(contentsOf: audioRecorder.url)
            let boundary = UUID().uuidString
            var request = URLRequest(url: URL(string: "http://192.168.253.49:8000/chartAi/upload_audio/")!)
            request.httpMethod = "POST"
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.mp3\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData ?? Data())
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            request.httpBody = body
            request.addValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error uploading recording: \(error.localizedDescription)")
                return
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Upload response: \(responseString)")
                DispatchQueue.main.async {
                    self.showSuccessAlert = true
                }
            }
        }.resume()
    }
}
