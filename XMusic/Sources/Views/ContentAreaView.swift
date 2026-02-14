//
//  ContentAreaView.swift
//  XMusic
//
//  内容区域视图
//

import SwiftUI

/// 内容区域视图
/// 根据选中的侧边栏项显示不同的内容
struct ContentAreaView: View {
    /// 选中的侧边栏项
    @Binding var selectedTab: SidebarItem
    /// 音乐库
    @ObservedObject var library: MusicLibrary
    /// 音频播放器
    @ObservedObject var player: AudioPlayer
    /// 搜索文本
    let searchText: String
    
    var body: some View {
        Group {
            // 根据选中的侧边栏项显示不同的内容
            switch selectedTab {
            case .library:
                // 显示歌曲列表
                TrackListView(
                    tracks: searchText.isEmpty ? library.tracks : library.search(query: searchText),
                    player: player,
                    library: library
                )
            case .albums:
                // 过滤专辑
                let filteredAlbums = searchText.isEmpty ? library.albums : library.albums.filter { album in
                    album.title.lowercased().contains(searchText.lowercased()) ||
                    album.artist.lowercased().contains(searchText.lowercased())
                }
                // 显示专辑网格
                AlbumGridView(
                    albums: filteredAlbums,
                    player: player,
                    library: library
                )
            case .artists:
                // 过滤艺术家
                let filteredArtists = searchText.isEmpty ? library.artists : library.artists.filter { artist in
                    artist.name.lowercased().contains(searchText.lowercased())
                }
                // 显示艺术家列表
                ArtistListView(
                    artists: filteredArtists,
                    player: player,
                    library: library
                )
            case .playlists:
                // 显示播放列表网格
                PlaylistGridView(
                    playlists: library.playlists,
                    library: library,
                    selectedTab: $selectedTab
                )
            case .playlist(let playlist):
                // 从 library 中获取最新的播放列表数据
                if let updatedPlaylist = library.playlists.first(where: { $0.id == playlist.id }) {
                    // 显示播放列表中的歌曲
                    TrackListView(
                        tracks: updatedPlaylist.tracks,
                        player: player,
                        library: library,
                        title: updatedPlaylist.name,
                        playlist: updatedPlaylist
                    )
                } else {
                    // 如果播放列表不存在，显示空的歌曲列表
                    TrackListView(
                        tracks: [],
                        player: player,
                        library: library,
                        title: playlist.name,
                        playlist: playlist
                    )
                }
            }
        }
    }
}

/// 歌曲列表视图
/// 显示歌曲列表，支持选择、删除等操作
struct TrackListView: View {
    /// 歌曲列表
    let tracks: [Track]
    /// 音频播放器
    @ObservedObject var player: AudioPlayer
    /// 音乐库
    @ObservedObject var library: MusicLibrary
    /// 标题
    var title: String = "歌曲"
    /// 播放列表（可选）
    var playlist: Playlist? = nil
    /// 是否进入选择模式
    @State private var selectionMode = false
    /// 选中的歌曲 ID 集合
    @State private var selectedTracks: Set<Track.ID> = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                
                if tracks.count > 0 {
                    if selectionMode {
                        // 选择模式下的按钮
                        HStack(spacing: 12) {
                            Button("全选") {
                                selectedTracks = Set(tracks.map { $0.id })
                            }
                            Button("取消选择") {
                                selectedTracks.removeAll()
                            }
                            Button("删除所选") {
                                if !selectedTracks.isEmpty {
                                    let tracksToRemove = tracks.filter { selectedTracks.contains($0.id) }
                                    for track in tracksToRemove {
                                        if let currentPlaylist = playlist {
                                            library.removeTrackFromPlaylist(track, playlist: currentPlaylist)
                                        } else {
                                            library.removeTrack(track)
                                        }
                                    }
                                    selectedTracks.removeAll()
                                    selectionMode = false
                                }
                            }
                            .foregroundStyle(.red)
                            Button("完成") {
                                selectionMode = false
                                selectedTracks.removeAll()
                            }
                        }
                    } else {
                        // 普通模式下的选择按钮
                        Button("选择") {
                            selectionMode = true
                        }
                    }
                }
                
                // 歌曲数量
                Text("\(tracks.count) 首歌曲")
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            // 歌曲列表
            List(tracks) { track in
                HStack(spacing: 8) {
                    if selectionMode {
                        // 选择按钮
                        Button(action: {
                            if selectedTracks.contains(track.id) {
                                selectedTracks.remove(track.id)
                            } else {
                                selectedTracks.insert(track.id)
                            }
                        }) {
                            Image(systemName: selectedTracks.contains(track.id) ? "checkmark.square.fill" : "square")
                                .foregroundStyle(selectedTracks.contains(track.id) ? .blue : .gray)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // 歌曲行视图
                    TrackRowView(
                        track: track,
                        isPlaying: player.currentTrack?.id == track.id && player.isPlaying,
                        isCurrentTrack: player.currentTrack?.id == track.id,
                        spectrumData: player.spectrumData
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectionMode {
                            // 切换选择状态
                            if selectedTracks.contains(track.id) {
                                selectedTracks.remove(track.id)
                            } else {
                                selectedTracks.insert(track.id)
                            }
                        } else {
                            // 播放歌曲
                            player.load(track: track, playlist: tracks)
                            player.play()
                        }
                    }
                    .contextMenu {
                        // 播放按钮
                        Button("播放") {
                            player.load(track: track, playlist: tracks)
                            player.play()
                        }
                        
                        // 添加到播放列表菜单
                        Menu("添加到播放列表") {
                            if library.playlists.isEmpty {
                                Button("暂无播放列表") {
                                    // 不做任何操作
                                }
                                .disabled(true)
                            } else {
                                ForEach(library.playlists) { targetPlaylist in
                                    // 避免添加到当前播放列表
                                    if targetPlaylist.id != playlist?.id {
                                        Button(action: {
                                            library.addTrackToPlaylist(track, playlist: targetPlaylist)
                                        }) {
                                            Text(targetPlaylist.name)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 只在播放列表视图中显示从播放列表中移除选项
                        if let currentPlaylist = playlist {
                            Button("从播放列表中移除") {
                                library.removeTrackFromPlaylist(track, playlist: currentPlaylist)
                            }
                        }
                        
                        Divider()
                        
                        // 在 Finder 中显示
                        Button("在 Finder 中显示") {
                            NSWorkspace.shared.activateFileViewerSelecting([track.url])
                        }
                        
                        // 从资料库删除
                        Button("从资料库删除") {
                            library.removeTrack(track)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

/// 歌曲行视图
/// 显示单个歌曲的详细信息
struct TrackRowView: View {
    /// 歌曲
    let track: Track
    /// 是否正在播放
    let isPlaying: Bool
    /// 是否是当前播放的歌曲
    let isCurrentTrack: Bool
    /// 频谱数据
    let spectrumData: [Float]
    /// 是否悬停
    @State private var isHovering = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 12) {
                // 歌曲封面
                ZStack {
                    if let artwork = track.artwork, let nsImage = NSImage(data: artwork) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let coverImage = loadLocalCoverImage(for: track) {
                        coverImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        // 默认封面
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 40, height: 40)
                .cornerRadius(4)
                
                // 歌曲信息
                VStack(alignment: .leading, spacing: 2) {
                Text(truncateText(track.title, maxLength: 50))
                    .font(.system(size: 13))
                    .fontWeight(isCurrentTrack ? .semibold : .regular)
                    .foregroundStyle(isCurrentTrack ? Color.accentColor : Color.primary)
                
                Text(track.artist)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 频谱视图（播放时显示）
            if isPlaying {
                SpectrumView(spectrumData: spectrumData)
                    .padding(.trailing, 10)
            }
            
            // 歌曲时长
            Text(track.formattedDuration)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
            }
            .padding(.vertical, 4)
            .background(isCurrentTrack ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onHover {
                isHovering = $0
            }
            
            // 悬停时显示完整标题
            if isHovering && track.title.count > 50 {
                Text(track.title)
                    .font(.system(size: 12))
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.8))
                    )
                    .foregroundStyle(.white)
                    .offset(x: 50, y: -10)
                    .zIndex(1000)
                    .fixedSize()
            }
        }
    }
    
    /// 截断文本
    /// - Parameters:
    ///   - text: 原始文本
    ///   - maxLength: 最大长度
    /// - Returns: 截断后的文本
    private func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength)) + "..."
    }
    
    /// 加载与歌曲同名的本地图片文件
    /// - Parameter track: 歌曲
    /// - Returns: 图片，失败则返回 nil
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

/// 播放指示器视图
/// 显示播放状态的动画指示器
struct PlayingIndicatorView: View {
    /// 是否正在动画
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.accentColor)
                    .frame(width: 3, height: animating ? 16 : 4)
                    .animation(
                        Animation.easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .frame(height: 16)
        .onAppear {
            animating = true
        }
    }
}

/// 频谱视图
/// 显示音频频谱的可视化效果
struct SpectrumView: View {
    /// 频谱数据
    let spectrumData: [Float]
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<min(spectrumData.count, 30), id: \.self) { index in
                let value = spectrumData[index]
                let height = CGFloat(value) * 40
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color(red: 0.2, green: 0.5, blue: 1.0),
                                    Color(red: 0.6, green: 0.2, blue: 1.0),
                                    Color(red: 1.0, green: 0.2, blue: 0.6)
                                ]
                            ),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: 4,
                        height: height
                    )
                    .shadow(color: Color.accentColor.opacity(0.5), radius: 2, x: 0, y: 2)
                    .animation(
                        Animation.easeOut(duration: 0.15).delay(Double(index) * 0.005),
                        value: height
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 4, height: 40)
                    )
            }
        }
        .frame(height: 40)
        .padding(.vertical, 2)
    }
}

/// 播放列表选择器视图
/// 用于选择将歌曲添加到哪个播放列表
struct PlaylistSelectorView: View {
    /// 歌曲
    let track: Track
    /// 音乐库
    @ObservedObject var library: MusicLibrary
    /// 是否显示
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("选择播放列表")
                .font(.title)
                .fontWeight(.bold)
            
            if library.playlists.isEmpty {
                // 没有播放列表时的提示
                VStack(spacing: 10) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("暂无播放列表")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("请先创建一个播放列表")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            } else {
                // 显示播放列表列表
                VStack(spacing: 5) {
                    ForEach(library.playlists) { playlist in
                        Button(action: {
                            library.addTrackToPlaylist(track, playlist: playlist)
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: "music.note.list")
                                    .padding(.trailing, 10)
                                Text(playlist.name)
                                Spacer()
                                Text("\(playlist.tracks.count) 首歌曲")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            
            // 取消按钮
            Button("取消") {
                isPresented = false
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(20)
        .frame(minWidth: 300, minHeight: 200)
    }
}
