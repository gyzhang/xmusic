import AVFoundation
import Combine

class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Double = 0.8
    @Published var currentTrack: Track?
    @Published var playbackProgress: Double = 0
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var playlist: [Track] = []
    private var currentIndex: Int = 0
    
    var canGoNext: Bool {
        currentIndex < playlist.count - 1
    }
    
    var canGoPrevious: Bool {
        currentIndex > 0
    }
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        #endif
    }
    
    func load(track: Track, playlist: [Track] = []) {
        self.playlist = playlist.isEmpty ? [track] : playlist
        self.currentIndex = self.playlist.firstIndex(where: { $0.id == track.id }) ?? 0
        self.currentTrack = track
        
        do {
            player = try AVAudioPlayer(contentsOf: track.url)
            player?.prepareToPlay()
            player?.volume = Float(volume)
            duration = player?.duration ?? 0
            currentTime = 0
            playbackProgress = 0
        } catch {
            print("Failed to load audio: \(error)")
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
        startProgressTimer()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        currentTime = 0
        playbackProgress = 0
        stopProgressTimer()
    }
    
    func nextTrack() {
        guard canGoNext else { return }
        currentIndex += 1
        let nextTrack = playlist[currentIndex]
        load(track: nextTrack, playlist: playlist)
        play()
    }
    
    func previousTrack() {
        guard canGoPrevious else { return }
        currentIndex -= 1
        let prevTrack = playlist[currentIndex]
        load(track: prevTrack, playlist: playlist)
        play()
    }
    
    func seek(to progress: Double) {
        guard let player = player else { return }
        let newTime = progress * duration
        player.currentTime = newTime
        currentTime = newTime
        playbackProgress = progress
    }
    
    func setVolume(_ newVolume: Double) {
        volume = newVolume
        player?.volume = Float(newVolume)
    }
    
    private func startProgressTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            self.currentTime = player.currentTime
            self.playbackProgress = self.duration > 0 ? self.currentTime / self.duration : 0
            
            if !player.isPlaying && self.isPlaying {
                self.isPlaying = false
                self.stopProgressTimer()
                if self.canGoNext {
                    self.nextTrack()
                }
            }
        }
    }
    
    private func stopProgressTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension AudioPlayer {
    static func supportedAudioExtensions() -> [String] {
        return ["mp3", "wav", "wave", "flac", "m4a", "aac", "aiff", "au", "snd", "sd2", "caf"]
    }
}
