import SwiftUI

struct AlbumGridView: View {
    let albums: [Album]
    @ObservedObject var player: AudioPlayer
    @ObservedObject var library: MusicLibrary
    @State private var selectedAlbum: Album?
    
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("专辑")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(albums.count) 张专辑")
                        .foregroundStyle(.secondary)
                }
                .padding()
                
                Divider()
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albums) { album in
                        AlbumCardView(album: album)
                            .onTapGesture {
                                selectedAlbum = album
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

struct AlbumCardView: View {
    let album: Album
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let artwork = album.artwork, let nsImage = NSImage(data: artwork) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
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

struct AlbumDetailView: View {
    let album: Album
    @ObservedObject var player: AudioPlayer
    @ObservedObject var library: MusicLibrary
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                HStack(spacing: 20) {
                    ZStack {
                        if let artwork = album.artwork, let nsImage = NSImage(data: artwork) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(album.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(album.artist)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 16) {
                            Label("\(album.tracks.count) 首歌曲", systemImage: "music.note")
                            Label(album.formattedDuration, systemImage: "clock")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        
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
                
                Section {
                    ForEach(album.tracks) { track in
                        TrackRowView(
                            track: track,
                            isPlaying: player.currentTrack?.id == track.id && player.isPlaying,
                            isCurrentTrack: player.currentTrack?.id == track.id
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
