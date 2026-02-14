import SwiftUI

/// 播放列表网格视图 - 显示所有播放列表的网格布局
struct PlaylistGridView: View {
    /// 播放列表数组
    let playlists: [Playlist]
    /// 音乐库实例
    @ObservedObject var library: MusicLibrary
    /// 当前选中的标签
    @Binding var selectedTab: SidebarItem
    /// 是否显示创建播放列表弹窗
    @State private var showingCreatePlaylist = false
    /// 新播放列表名称
    @State private var newPlaylistName = ""
    
    /// 网格列配置
    let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 标题栏
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
                
                // 空播放列表视图
                if playlists.isEmpty {
                    EmptyPlaylistView()
                } else {
                    // 播放列表网格
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

/// 播放列表卡片视图 - 显示单个播放列表的卡片
struct PlaylistCardView: View {
    /// 播放列表数据
    let playlist: Playlist
    /// 音乐库实例
    @ObservedObject var library: MusicLibrary
    /// 是否悬停状态
    @State private var isHovering = false
    /// 点击回调
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 播放列表封面
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
            
            // 播放列表信息
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
    
    /// 生成播放列表封面的渐变颜色
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
    
    /// 格式化日期为相对时间
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// 空播放列表视图 - 当没有播放列表时显示
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

/// 创建播放列表弹窗 - 用于新建播放列表
struct CreatePlaylistSheet: View {
    /// 是否显示弹窗
    @Binding var isPresented: Bool
    /// 播放列表名称
    @Binding var playlistName: String
    /// 创建回调
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
