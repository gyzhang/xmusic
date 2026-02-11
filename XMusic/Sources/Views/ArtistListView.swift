import SwiftUI

struct ArtistListView: View {
    let artists: [Artist]
    @ObservedObject var player: AudioPlayer
    @ObservedObject var library: MusicLibrary
    @State private var selectedArtist: Artist?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("艺人")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Text("\(artists.count) 位艺人")
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            List(artists) { artist in
                ArtistRowView(artist: artist)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedArtist = artist
                    }
            }
            .listStyle(.plain)
        }
        .sheet(item: $selectedArtist) { artist in
            ArtistDetailView(artist: artist, player: player, library: library)
        }
    }
}

struct ArtistRowView: View {
    let artist: Artist
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
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
                    .frame(width: 50, height: 50)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.system(size: 15, weight: .semibold))
                
                Text("\(artist.albums.count) 张专辑 · \(artist.tracks.count) 首歌曲")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct ArtistDetailView: View {
    let artist: Artist
    @ObservedObject var player: AudioPlayer
    @ObservedObject var library: MusicLibrary
    @Environment(\.dismiss) private var dismiss
    
    let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 20) {
                        ZStack {
                            Circle()
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
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 180, height: 180)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(artist.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 16) {
                                Label("\(artist.albums.count) 张专辑", systemImage: "square.stack")
                                Label("\(artist.tracks.count) 首歌曲", systemImage: "music.note")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            
                            HStack(spacing: 12) {
                                Button("播放全部") {
                                    let allTracks = artist.tracks
                                    if let firstTrack = allTracks.first {
                                        player.load(track: firstTrack, playlist: allTracks)
                                        player.play()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("随机播放") {
                                    let shuffled = artist.tracks.shuffled()
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
                    
                    Divider()
                    
                    Text("专辑")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(artist.albums) { album in
                            AlbumCardView(album: album)
                                .onTapGesture {
                                    // 播放专辑
                                    if let firstTrack = album.tracks.first {
                                        player.load(track: firstTrack, playlist: album.tracks)
                                        player.play()
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical)
                    
                    Text("歌曲")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        ForEach(artist.tracks) { track in
                            TrackRowView(
                                track: track,
                                isPlaying: player.currentTrack?.id == track.id && player.isPlaying,
                                isCurrentTrack: player.currentTrack?.id == track.id
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                player.load(track: track, playlist: artist.tracks)
                                player.play()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(artist.name)
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
