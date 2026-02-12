import SwiftUI
import Cocoa

struct ContentView: View {
    @StateObject private var player = AudioPlayer()
    @StateObject private var library = MusicLibrary()
    @State private var selectedTab: SidebarItem = .library
    @State private var searchText = ""
    @State private var showingAddFiles = false
    @State private var showingAddDirectory = false
    
    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedTab: $selectedTab,
                library: library,
                searchText: $searchText
            )
            .frame(minWidth: 200, idealWidth: 240)
        } content: {
            ContentAreaView(
                selectedTab: selectedTab,
                library: library,
                player: player,
                searchText: searchText
            )
            .frame(minWidth: 500, idealWidth: 600)
        } detail: {
            NowPlayingView(player: player, library: library)
                .frame(minWidth: 350, idealWidth: 400)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { presentAddFilesPanel() }) {
                    Image(systemName: "plus")
                }
                .help("添加音乐文件")
                
                Button(action: { presentAddDirectoryPanel() }) {
                    Image(systemName: "folder.badge.plus")
                }
                .help("扫描文件夹")
            }
        }

        .environmentObject(player)
        .environmentObject(library)
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            library.addFiles(urls)
        case .failure(let error):
            print("Failed to import files: \(error)")
        }
    }
    
    private func handleDirectoryImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            library.scanDirectory(url)
        case .failure(let error):
            print("Failed to import directory: \(error)")
        }
    }
    
    private func presentAddFilesPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.title = "选择音乐文件"
        
        panel.begin { response in
            if response == .OK {
                let urls = panel.urls
                library.addFiles(urls)
            }
        }
    }
    
    private func presentAddDirectoryPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.directory]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "选择音乐文件夹"
        
        panel.begin { response in
            if response == .OK,
               let url = panel.urls.first {
                library.scanDirectory(url)
            }
        }
    }
}

enum SidebarItem: Hashable {
    case library
    case albums
    case artists
    case playlists
    case playlist(Playlist)
}
