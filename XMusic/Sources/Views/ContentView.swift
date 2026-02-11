import SwiftUI

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
            .frame(minWidth: 400, idealWidth: 500)
        } detail: {
            NowPlayingView(player: player, library: library)
                .frame(minWidth: 350, idealWidth: 400)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showingAddFiles = true }) {
                    Image(systemName: "plus")
                }
                .help("添加音乐文件")
                
                Button(action: { showingAddDirectory = true }) {
                    Image(systemName: "folder.badge.plus")
                }
                .help("扫描文件夹")
            }
        }
        .fileImporter(
            isPresented: $showingAddFiles,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .fileImporter(
            isPresented: $showingAddDirectory,
            allowedContentTypes: [.directory]
        ) { result in
            handleDirectoryImport(result)
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
}

enum SidebarItem: Hashable {
    case library
    case albums
    case artists
    case playlists
    case playlist(Playlist)
}
