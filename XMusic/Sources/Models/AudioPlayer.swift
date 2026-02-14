//
//  AudioPlayer.swift
//  XMusic
//
//  音频播放器
//

import AVFoundation
import Combine
import Accelerate

/// 音频播放器
/// 负责音频播放控制、播放进度管理、频谱分析等功能
class AudioPlayer: ObservableObject {
    /// 是否正在播放
    @Published var isPlaying = false
    /// 当前播放时间（秒）
    @Published var currentTime: TimeInterval = 0
    /// 音频总时长（秒）
    @Published var duration: TimeInterval = 0
    /// 音量（0.0-1.0）
    @Published var volume: Double = 0.8
    /// 当前播放的歌曲
    @Published var currentTrack: Track?
    /// 播放进度（0.0-1.0）
    @Published var playbackProgress: Double = 0
    /// 频谱数据（用于可视化）
    @Published var spectrumData: [Float] = Array(repeating: 0.0, count: 30)
    
    /// 音频播放器
    private var player: AVAudioPlayer?
    /// 进度更新定时器
    private var timer: Timer?
    /// 播放列表
    private var playlist: [Track] = []
    /// 当前播放索引
    private var currentIndex: Int = 0
    /// 音频引擎（用于频谱分析）
    private var audioEngine: AVAudioEngine?
    /// 音频混音节点
    private var audioMixerNode: AVAudioMixerNode?
    /// 频谱分析定时器
    private var spectrumTimer: Timer?
    /// 音频播放器节点
    private var audioPlayerNode: AVAudioPlayerNode?
    /// 音频文件
    private var audioFile: AVAudioFile?
    /// 音频缓冲区
    private var audioBuffer: AVAudioPCMBuffer?
    
    /// 是否可以播放下一首
    var canGoNext: Bool {
        currentIndex < playlist.count - 1
    }
    
    /// 是否可以播放上一首
    var canGoPrevious: Bool {
        currentIndex > 0
    }
    
    /// 初始化方法
    init() {
        setupAudioSession()
    }
    
    /// 设置音频会话
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
    
    /// 加载歌曲
    /// - Parameters:
    ///   - track: 要加载的歌曲
    ///   - playlist: 播放列表（默认为空）
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
    
    /// 设置音频引擎
    /// - Parameter track: 当前播放的歌曲
    private func setupAudioEngine(for track: Track) {
        // 简化实现，直接启动频谱分析（使用模拟数据）
        startSpectrumAnalysis()
    }
    
    /// 停止音频引擎
    private func stopAudioEngine() {
        spectrumTimer?.invalidate()
        spectrumData = Array(repeating: 0.0, count: 30)
    }
    
    /// 开始频谱分析
    private func startSpectrumAnalysis() {
        // 开始定时器更新频谱数据
        spectrumTimer?.invalidate()
        spectrumTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            
            // 简化的频谱模拟
            self.generateSpectrumData()
        }
    }
    
    /// 生成模拟频谱数据
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
    
    /// 播放音频
    func play() {
        player?.play()
        isPlaying = true
        startProgressTimer()
    }
    
    /// 暂停音频
    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
    }
    
    /// 切换播放/暂停状态
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    /// 停止音频
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
    
    /// 播放下一首
    func nextTrack() {
        guard canGoNext else { return }
        currentIndex += 1
        let nextTrack = playlist[currentIndex]
        load(track: nextTrack, playlist: playlist)
        play()
    }
    
    /// 播放上一首
    func previousTrack() {
        guard canGoPrevious else { return }
        currentIndex -= 1
        let prevTrack = playlist[currentIndex]
        load(track: prevTrack, playlist: playlist)
        play()
    }
    
    /// 跳转到指定进度
    /// - Parameter progress: 进度（0.0-1.0）
    func seek(to progress: Double) {
        guard let player = player else { return }
        let newTime = progress * (player.duration)
        player.currentTime = newTime
        currentTime = newTime
        playbackProgress = progress
    }
    
    /// 设置音量
    /// - Parameter newVolume: 音量（0.0-1.0）
    func setVolume(_ newVolume: Double) {
        volume = newVolume
        player?.volume = Float(newVolume)
    }
    
    /// 开始进度更新定时器
    private func startProgressTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            self.currentTime = player.currentTime
            self.playbackProgress = self.duration > 0 ? self.currentTime / self.duration : 0
            
            // 检查是否播放完成
            if !player.isPlaying && self.isPlaying {
                self.isPlaying = false
                self.stopProgressTimer()
                // 自动播放下一首
                if self.canGoNext {
                    self.nextTrack()
                }
            }
        }
    }
    
    /// 停止进度更新定时器
    private func stopProgressTimer() {
        timer?.invalidate()
        timer = nil
    }
}

/// AudioPlayer 扩展

extension AudioPlayer {
    /// 获取支持的音频文件扩展名
    /// - Returns: 支持的音频文件扩展名列表
    static func supportedAudioExtensions() -> [String] {
        return ["mp3", "wav", "wave", "flac", "m4a", "aac", "aiff", "au", "snd", "sd2", "caf"]
    }
}
