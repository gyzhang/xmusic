import SwiftUI

struct PlaylistGridView: View {
    let playlists: [Playlist]
    @ObservedObject var library: MusicLibrary
    @Binding var selectedTab: SidebarItem
    @State private var showingCreatePlaylist = false
    @State private var newPlaylistName = ""
    
    let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("播放列表")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    
                    Button(action: { showingCreatePlaylist = true }) {
                        Label("新建播放列表", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                Divider()
                
                if playlists.isEmpty {
                    EmptyPlaylistView()
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(playlists) { playlist in
                            PlaylistCardView(
                                playlist: playlist, 
                                library: library,
                                onTap: {
                                    selectedTab = .playlist(playlist)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingCreatePlaylist) {
            CreatePlaylistSheet(
                isPresented: $showingCreatePlaylist,
                playlistName: $newPlaylistName,
                onCreate: {
                    if !newPlaylistName.isEmpty {
                        library.createPlaylist(name: newPlaylistName)
                        newPlaylistName = ""
                    }
                }
            )
        }
    }
}

struct PlaylistCardView: View {
    let playlist: Playlist
    @ObservedObject var library: MusicLibrary
    @State private var isHovering = false
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundStyle(.white.opacity(0.3))
                    )
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
                Text(playlist.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                Text("\(playlist.tracks.count) 首歌曲")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                Text(formattedDate(playlist.createdAt))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
        .contextMenu {
            Button("删除播放列表") {
                library.deletePlaylist(playlist)
            }
        }
    }
    
    private var gradientColors: [Color] {
        let colors: [Color] = [
            .pink.opacity(0.8),
            .purple.opacity(0.8),
            .blue.opacity(0.8),
            .green.opacity(0.8),
            .orange.opacity(0.8),
            .red.opacity(0.8)
        ]
        let index = abs(playlist.name.hashValue) % colors.count
        return [colors[index], colors[(index + 1) % colors.count]]
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct EmptyPlaylistView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("没有播放列表")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("点击右上角的按钮创建你的第一个播放列表")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct CreatePlaylistSheet: View {
    @Binding var isPresented: Bool
    @Binding var playlistName: String
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("新建播放列表")
                .font(.headline)
            
            TextField("播放列表名称", text: $playlistName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)
            
            HStack(spacing: 12) {
                Button("取消") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                Button("创建") {
                    onCreate()
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(playlistName.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
