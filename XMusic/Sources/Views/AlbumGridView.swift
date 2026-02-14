import SwiftUI

/// 专辑网格视图 - 显示所有专辑的网格布局
struct AlbumGridView: View {
    /// 专辑数组
    let albums: [Album]
    /// 音频播放器实例
    @ObservedObject var player: AudioPlayer
    /// 音乐库实例
    @ObservedObject var library: MusicLibrary
    /// 当前选中的专辑
    @State private var selectedAlbum: Album?
    /// 是否处于选择模式
    @State private var selectionMode = false
    /// 选中的专辑ID集合
    @State private var selectedAlbums: Set<Album.ID> = []
    
    /// 网格列配置
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 标题栏
                HStack {
                    Text("专辑")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(albums.count) 张专辑")
                        .foregroundStyle(.secondary)
                    if albums.count > 0 {
                        Button(selectionMode ? "完成" : "编辑") {
                            if selectionMode {
                                selectionMode = false
                                selectedAlbums.removeAll()
                            } else {
                                selectionMode = true
                            }
                        }
                        .padding(.leading, 16)
                    }
                }
                .padding()
                
                Divider()
                
                // 选择模式工具栏
                if selectionMode {
                    HStack {
                        Button("全选") {
                            selectedAlbums = Set(albums.map { $0.id })
                        }
                        Button("取消选择") {
                            selectedAlbums.removeAll()
                        }
                        Button("删除所选") {
                            if !selectedAlbums.isEmpty {
                                let albumsToRemove = albums.filter { selectedAlbums.contains($0.id) }
                                for album in albumsToRemove {
                                    library.removeAlbum(album)
                                }
                                selectedAlbums.removeAll()
                                selectionMode = false
                            }
                        }
                        .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                }
                
                // 专辑网格
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albums) { album in
                        AlbumCardView(album: album)
                            .overlay {
                                if selectionMode {
                                    ZStack {
                                        Color.black.opacity(0.3)
                                        Image(systemName: selectedAlbums.contains(album.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 24))
                                            .foregroundStyle(selectedAlbums.contains(album.id) ? .blue : .white)
                                            .position(x: 20, y: 20)
                                    }
                                    .onTapGesture {
                                        if selectedAlbums.contains(album.id) {
                                            selectedAlbums.remove(album.id)
                                        } else {
                                            selectedAlbums.insert(album.id)
                                        }
                                    }
                                } else {
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedAlbum = album
                                        }
                                }
                            }
                    }
                }
                .padding()
            }
        }
        .sheet(item: $selectedAlbum) { album in
            AlbumDetailView(album: album, player: player, library: library)
        }
    }
}

/// 专辑卡片视图 - 显示单个专辑的卡片
struct AlbumCardView: View {
    /// 专辑数据
    let album: Album
    /// 是否悬停状态
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 专辑封面
            ZStack {
                if let artwork = album.artwork, let nsImage = NSImage(data: artwork) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // 无封面时的默认显示
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
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
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(isHovering ? 0.2 : 0.1), radius: isHovering ? 12 : 8, x: 0, y: isHovering ? 6 : 4)
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
            
            // 专辑信息
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                
                Text(album.artist)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text("\(album.tracks.count) 首歌曲")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// 专辑详情视图 - 显示专辑的详细信息和曲目列表
struct AlbumDetailView: View {
    /// 专辑数据
    let album: Album
    /// 音频播放器实例
    @ObservedObject var player: AudioPlayer
    /// 音乐库实例
    @ObservedObject var library: MusicLibrary
    /// 关闭视图的环境变量
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // 专辑封面和基本信息
                HStack(spacing: 20) {
                    ZStack {
                        if let artwork = album.artwork, let nsImage = NSImage(data: artwork) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            // 无封面时的默认显示
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
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                    
                    // 专辑信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text(album.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(album.artist)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        // 专辑统计信息
                        HStack(spacing: 16) {
                            Label("\(album.tracks.count) 首歌曲", systemImage: "music.note")
                            Label(album.formattedDuration, systemImage: "clock")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        
                        // 播放按钮
                        HStack(spacing: 12) {
                            Button("播放全部") {
                                if let firstTrack = album.tracks.first {
                                    player.load(track: firstTrack, playlist: album.tracks)
                                    player.play()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("随机播放") {
                                let shuffled = album.tracks.shuffled()
                                if let firstTrack = shuffled.first {
                                    player.load(track: firstTrack, playlist: shuffled)
                                    player.play()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 16)
                    }
                    
                    Spacer()
                }
                .padding()
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // 曲目列表
                Section {
                    ForEach(album.tracks) { track in
                        TrackRowView(
                            track: track,
                            isPlaying: player.currentTrack?.id == track.id && player.isPlaying,
                            isCurrentTrack: player.currentTrack?.id == track.id,
                            spectrumData: player.spectrumData
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            player.load(track: track, playlist: album.tracks)
                            player.play()
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(album.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}
