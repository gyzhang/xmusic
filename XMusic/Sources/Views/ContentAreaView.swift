import SwiftUI

struct ContentAreaView: View {
    let selectedTab: SidebarItem
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
                AlbumGridView(
                    albums: library.albums,
                    player: player,
                    library: library
                )
            case .artists:
                ArtistListView(
                    artists: library.artists,
                    player: player,
                    library: library
                )
            case .playlists:
                PlaylistGridView(
                    playlists: library.playlists,
                    library: library
                )
            case .playlist(let playlist):
                TrackListView(
                    tracks: playlist.tracks,
                    player: player,
                    library: library,
                    title: playlist.name
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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Text("\(tracks.count) 首歌曲")
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            List(tracks) { track in
                TrackRowView(
                    track: track,
                    isPlaying: player.currentTrack?.id == track.id && player.isPlaying,
                    isCurrentTrack: player.currentTrack?.id == track.id
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    player.load(track: track, playlist: tracks)
                    player.play()
                }
                .contextMenu {
                    Button("播放") {
                        player.load(track: track, playlist: tracks)
                        player.play()
                    }
                    
                    Button("添加到播放列表") {
                        // TODO: 显示播放列表选择器
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
            .listStyle(.plain)
        }
    }
}

struct TrackRowView: View {
    let track: Track
    let isPlaying: Bool
    let isCurrentTrack: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if let artwork = track.artwork, let nsImage = NSImage(data: artwork) {
                    Image(nsImage: nsImage)
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
                Text(track.title)
                    .font(.system(size: 13))
                    .fontWeight(isCurrentTrack ? .semibold : .regular)
                    .foregroundStyle(isCurrentTrack ? Color.accentColor : Color.primary)
                
                Text(track.artist)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isPlaying {
                PlayingIndicatorView()
                    .frame(width: 20, height: 20)
            }
            
            Text(track.formattedDuration)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .background(isCurrentTrack ? Color.accentColor.opacity(0.1) : Color.clear)
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
