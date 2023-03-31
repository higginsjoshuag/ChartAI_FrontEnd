//import AVFoundation
//
//class AudioPlaybackManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
//    @Published var isPlaying = false
//    private var audioPlayer: AVAudioPlayer?
//    
//    func playRecording(url: URL) {
//        guard !isPlaying else { return }
//
//        do {
//            audioPlayer = try AVAudioPlayer(contentsOf: url)
//            audioPlayer?.delegate = self
//            audioPlayer?.play()
//            isPlaying = true
//        } catch {
//            print("Failed to play the recording: \(error.localizedDescription)")
//        }
//    }
//    
//    func stopPlayback() {
//        audioPlayer?.stop()
//        isPlaying = false
//    }
//
//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        isPlaying = false
//    }
//}
