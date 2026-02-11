import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: SidebarItem
    @ObservedObject var library: MusicLibrary
    @Binding var searchText: String
    
    var body: some View {
        List(selection: Binding(
            get: { selectedTab },
            set: { if let newValue = $0 { selectedTab = newValue } }
        )) {
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
            
            Section("播放列表") {
                NavigationLink(value: SidebarItem.playlists) {
                    Label("所有播放列表", systemImage: "list.bullet")
                }
                
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
