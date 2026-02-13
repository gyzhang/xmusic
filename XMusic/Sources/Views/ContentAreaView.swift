import SwiftUI

struct ContentAreaView: View {
    @Binding var selectedTab: SidebarItem
    @ObservedObject var library: MusicLibrary
    @ObservedObject var player: AudioPlayer
    let searchText: String
    
    var body: some View {
        Group {
            switch selectedTab {
            case .library:
                TrackListView(
                    tracks: searchText.isEmpty ? library.tracks : library.search(query: searchText),
                    player: player,
                    library: library
                )
            case .albums:
                let filteredAlbums = searchText.isEmpty ? library.albums : library.albums.filter { album in
                    album.title.lowercased().contains(searchText.lowercased()) ||
                    album.artist.lowercased().contains(searchText.lowercased())
                }
                AlbumGridView(
                    albums: filteredAlbums,
                    player: player,
                    library: library
                )
            case .artists:
                let filteredArtists = searchText.isEmpty ? library.artists : library.artists.filter { artist in
                    artist.name.lowercased().contains(searchText.lowercased())
                }
                ArtistListView(
                    artists: filteredArtists,
                    player: player,
                    library: library
                )
            case .playlists:
                PlaylistGridView(
                    playlists: library.playlists,
                    library: library,
                    selectedTab: $selectedTab
                )
            case .playlist(let playlist):
                TrackListView(
                    tracks: playlist.tracks,
                    player: player,
                    library: library,
                    title: playlist.name,
                    playlist: playlist
                )
            }
        }
    }
}

struct TrackListView: View {
    let tracks: [Track]
    @ObservedObject var player: AudioPlayer
    @ObservedObject var library: MusicLibrary
    var title: String = "歌曲"
    var playlist: Playlist? = nil
    @State private var selectionMode = false
    @State private var selectedTracks: Set<Track.ID> = []
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                
                if tracks.count > 0 {
                    if selectionMode {
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
                        Button("选择") {
                            selectionMode = true
                        }
                    }
                }
                
                Text("\(tracks.count) 首歌曲")
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            List(tracks) { track in
                HStack(spacing: 8) {
                    if selectionMode {
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
                    
                    TrackRowView(
                        track: track,
                        isPlaying: player.currentTrack?.id == track.id && player.isPlaying,
                        isCurrentTrack: player.currentTrack?.id == track.id,
                        spectrumData: player.spectrumData
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectionMode {
                            if selectedTracks.contains(track.id) {
                                selectedTracks.remove(track.id)
                            } else {
                                selectedTracks.insert(track.id)
                            }
                        } else {
                            player.load(track: track, playlist: tracks)
                            player.play()
                        }
                    }
                    .contextMenu {
                        Button("播放") {
                            player.load(track: track, playlist: tracks)
                            player.play()
                        }
                        
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
                        
                        Button("在 Finder 中显示") {
                            NSWorkspace.shared.activateFileViewerSelecting([track.url])
                        }
                        
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

struct TrackRowView: View {
    let track: Track
    let isPlaying: Bool
    let isCurrentTrack: Bool
    let spectrumData: [Float]
    @State private var isHovering = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 12) {
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
            
            if isPlaying {
                SpectrumView(spectrumData: spectrumData)
                    .padding(.trailing, 10)
            }
            
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
    
    private func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength)) + "..."
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

struct PlayingIndicatorView: View {
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

struct SpectrumView: View {
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

struct PlaylistSelectorView: View {
    let track: Track
    @ObservedObject var library: MusicLibrary
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("选择播放列表")
                .font(.title)
                .fontWeight(.bold)
            
            if library.playlists.isEmpty {
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
