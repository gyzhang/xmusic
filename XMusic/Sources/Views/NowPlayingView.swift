import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var player: AudioPlayer
    @ObservedObject var library: MusicLibrary
    @State private var showingPlaylist = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 专辑封面区域
            AlbumArtworkView(track: player.currentTrack)
                .padding(.horizontal, 40)
                .padding(.top, 40)
            
            Spacer()
            
            // 歌曲信息
            VStack(spacing: 8) {
                Text(player.currentTrack?.title ?? "未在播放")
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(1)
                
                Text(player.currentTrack?.artist ?? "选择一首歌曲开始播放")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 播放控制区域
            VStack(spacing: 20) {
                // 进度条
                ProgressBarView(player: player)
                    .padding(.horizontal, 20)
                
                // 控制按钮
                PlaybackControlsView(player: player)
                
                // 音量控制
                VolumeControlView(player: player)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(NSColor.controlBackgroundColor),
                    Color(NSColor.windowBackgroundColor)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct AlbumArtworkView: View {
    let track: Track?
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            if let track = track {
                // 首先尝试加载音频文件内置的封面
                if let artwork = track.artwork, let nsImage = NSImage(data: artwork) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let coverImage = loadLocalCoverImage(for: track) {
                    // 尝试加载与歌曲同名的本地图片文件
                    coverImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // 显示默认占位符
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                // 显示默认占位符
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.3),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // 加载与歌曲同名的本地图片文件
    private func loadLocalCoverImage(for track: Track) -> Image? {
        // 获取歌曲文件所在目录
        let directory = track.url.deletingLastPathComponent()
        
        // 尝试常见的图片扩展名
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp"]
        
        // 1. 首先尝试加载与歌曲同名的图片文件
        let fileName = track.url.deletingPathExtension().lastPathComponent
        for ext in imageExtensions {
            let imageURL = directory.appendingPathComponent("\(fileName).\(ext)")
            if FileManager.default.fileExists(atPath: imageURL.path) {
                if let nsImage = NSImage(contentsOf: imageURL) {
                    return Image(nsImage: nsImage)
                }
            }
        }
        
        // 2. 如果找不到同名图片，尝试加载同目录下名为 "cover" 的图片文件
        for ext in imageExtensions {
            let imageURL = directory.appendingPathComponent("cover.\(ext)")
            if FileManager.default.fileExists(atPath: imageURL.path) {
                if let nsImage = NSImage(contentsOf: imageURL) {
                    return Image(nsImage: nsImage)
                }
            }
        }
        
        return nil
    }
}

struct ProgressBarView: View {
    @ObservedObject var player: AudioPlayer
    @State private var isDragging = false
    @State private var dragProgress: Double = 0
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    // 进度
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * CGFloat(isDragging ? dragProgress : player.playbackProgress), height: 4)
                    
                    // 拖动圆点
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: isDragging ? 14 : 10, height: isDragging ? 14 : 10)
                        .shadow(radius: isDragging ? 4 : 2)
                        .offset(x: geometry.size.width * CGFloat(isDragging ? dragProgress : player.playbackProgress) - (isDragging ? 7 : 5))
                        .animation(.easeInOut(duration: 0.1), value: isDragging)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            dragProgress = min(max(Double(value.location.x / geometry.size.width), 0), 1)
                        }
                        .onEnded { _ in
                            player.seek(to: dragProgress)
                            isDragging = false
                        }
                )
            }
            .frame(height: 40)
            
            HStack {
                Text(formatTime(isDragging ? dragProgress * player.duration : player.currentTime))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                
                Spacer()
                
                Text(formatTime(player.duration))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && time >= 0 else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct PlaybackControlsView: View {
    @ObservedObject var player: AudioPlayer
    
    var body: some View {
        HStack(spacing: 30) {
            Button(action: { player.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 20))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!player.canGoPrevious)
            .opacity(player.canGoPrevious ? 1 : 0.3)
            
            Button(action: { player.togglePlayPause() }) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(player.currentTrack == nil)
            .opacity(player.currentTrack == nil ? 0.5 : 1)
            
            Button(action: { player.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 20))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!player.canGoNext)
            .opacity(player.canGoNext ? 1 : 0.3)
        }
    }
}

struct VolumeControlView: View {
    @ObservedObject var player: AudioPlayer
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: volumeIcon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * CGFloat(player.volume), height: 4)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newVolume = min(max(Double(value.location.x / geometry.size.width), 0), 1)
                            player.setVolume(newVolume)
                        }
                )
            }
            .frame(height: 20)
        }
    }
    
    private var volumeIcon: String {
        if player.volume == 0 {
            return "speaker.slash.fill"
        } else if player.volume < 0.3 {
            return "speaker.fill"
        } else if player.volume < 0.7 {
            return "speaker.wave.1.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
}
