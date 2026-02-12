import AVFoundation
import Combine
import Accelerate

class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Double = 0.8
    @Published var currentTrack: Track?
    @Published var playbackProgress: Double = 0
    @Published var spectrumData: [Float] = Array(repeating: 0.0, count: 30)
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var playlist: [Track] = []
    private var currentIndex: Int = 0
    private var audioEngine: AVAudioEngine?
    private var audioMixerNode: AVAudioMixerNode?
    private var spectrumTimer: Timer?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    private var audioBuffer: AVAudioPCMBuffer?
    
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
            // 停止之前的音频引擎
            stopAudioEngine()
            
            // 设置传统的 AVAudioPlayer（用于基本播放控制）
            player = try AVAudioPlayer(contentsOf: track.url)
            player?.prepareToPlay()
            player?.volume = Float(volume)
            duration = player?.duration ?? 0
            currentTime = 0
            playbackProgress = 0
            
            // 设置音频引擎用于频谱分析
            setupAudioEngine(for: track)
        } catch {
            print("Failed to load audio: \(error)")
        }
    }
    
    private func setupAudioEngine(for track: Track) {
        // 简化实现，直接启动频谱分析（使用模拟数据）
        startSpectrumAnalysis()
    }
    
    private func stopAudioEngine() {
        spectrumTimer?.invalidate()
        spectrumData = Array(repeating: 0.0, count: 30)
    }
    
    private func startSpectrumAnalysis() {
        // 开始定时器更新频谱数据
        spectrumTimer?.invalidate()
        spectrumTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            
            // 简化的频谱模拟
            self.generateSpectrumData()
        }
    }
    
    private func generateSpectrumData() {
        var magnitudes = [Float](repeating: 0.0, count: spectrumData.count)
        
        // 时间因子
        let timeFactor = Float(Date().timeIntervalSince1970 * 15.0)
        
        // 生成模拟频谱数据
        for i in 0..<spectrumData.count {
            // 为不同频率范围设置不同的参数
            var frequencyMultiplier: Float
            var amplitudeMultiplier: Float
            
            // 低频范围 (0-9)
            if i < 10 {
                frequencyMultiplier = 0.1 + Float(i) * 0.05
                amplitudeMultiplier = 0.8 + Float(i) * 0.02
            }
            // 中频范围 (10-19)
            else if i < 20 {
                frequencyMultiplier = 0.6 + Float(i-10) * 0.08
                amplitudeMultiplier = 1.0 + Float(i-10) * 0.01
            }
            // 高频范围 (20-29)
            else {
                frequencyMultiplier = 1.4 + Float(i-20) * 0.1
                amplitudeMultiplier = 0.7 + Float(i-20) * 0.03
            }
            
            // 基础波形 - 组合多个正弦波以增加复杂度
            let baseValue1 = sin(Float(i) * frequencyMultiplier + timeFactor * 0.1) * 0.5
            let baseValue2 = sin(Float(i) * frequencyMultiplier * 1.5 + timeFactor * 0.15) * 0.3
            let baseValue3 = sin(Float(i) * frequencyMultiplier * 2.0 + timeFactor * 0.2) * 0.2
            let combinedValue = (baseValue1 + baseValue2 + baseValue3) + 0.5
            
            // 添加随机变化
            let randomFactor = Float.random(in: 0.5...1.5)
            
            // 计算最终值
            var finalValue = combinedValue * amplitudeMultiplier * randomFactor
            
            // 偶尔添加突发峰值
            let peakChance = Float.random(in: 0.0...1.0)
            if peakChance < 0.1 {
                finalValue += Float.random(in: 0.3...0.8)
            }
            
            // 限制在 0.0 到 1.0 之间
            magnitudes[i] = min(max(finalValue, 0.0), 1.0)
        }
        
        // 更新频谱数据
        spectrumData = magnitudes
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
        timer?.invalidate()
        currentTime = 0
        playbackProgress = 0
        spectrumData = Array(repeating: 0.0, count: 30)
        stopAudioEngine()
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
        let newTime = progress * (player.duration)
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
