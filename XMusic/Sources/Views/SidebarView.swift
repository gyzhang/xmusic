//
//  SidebarView.swift
//  XMusic
//
//  侧边栏视图
//

import SwiftUI

/// 侧边栏视图
/// 显示应用程序的导航选项，包括资料库和播放列表
struct SidebarView: View {
    /// 选中的侧边栏项
    @Binding var selectedTab: SidebarItem
    /// 音乐库
    @ObservedObject var library: MusicLibrary
    /// 搜索文本
    @Binding var searchText: String
    
    var body: some View {
        List(selection: Binding(
            get: { selectedTab },
            set: { if let newValue = $0 { selectedTab = newValue } }
        )) {
            // 资料库部分
            Section("资料库") {
                NavigationLink(value: SidebarItem.library) {
                    Label("歌曲", systemImage: "music.note")
                }
                
                NavigationLink(value: SidebarItem.albums) {
                    Label("专辑", systemImage: "square.stack")
                }
                
                NavigationLink(value: SidebarItem.artists) {
                    Label("艺人", systemImage: "person.2")
                }
            }
            
            // 播放列表部分
            Section("播放列表") {
                NavigationLink(value: SidebarItem.playlists) {
                    Label("所有播放列表", systemImage: "list.bullet")
                }
                
                // 显示所有播放列表
                ForEach(library.playlists) { playlist in
                    NavigationLink(value: SidebarItem.playlist(playlist)) {
                        Label(playlist.name, systemImage: "music.note.list")
                    }
                    .contextMenu {
                        Button("删除") {
                            library.deletePlaylist(playlist)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, prompt: "搜索")
    }
}
