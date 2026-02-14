//
//  ContentView.swift
//  XMusic
//
//  主视图
//

import SwiftUI
import Cocoa

/// 主视图
/// 应用程序的根视图，包含侧边栏、内容区域和播放控制区域
struct ContentView: View {
    /// 音频播放器
    @StateObject private var player = AudioPlayer()
    /// 音乐库
    @StateObject private var library = MusicLibrary()
    /// 选中的侧边栏项
    @State private var selectedTab: SidebarItem = .library
    /// 搜索文本
    @State private var searchText = ""
    /// 是否显示添加文件面板
    @State private var showingAddFiles = false
    /// 是否显示添加目录面板
    @State private var showingAddDirectory = false
    
    var body: some View {
        NavigationSplitView {
            // 侧边栏视图
            SidebarView(
                selectedTab: $selectedTab,
                library: library,
                searchText: $searchText
            )
            .frame(minWidth: 200, idealWidth: 240)
        } content: {
            // 内容区域视图
            ContentAreaView(
                selectedTab: $selectedTab,
                library: library,
                player: player,
                searchText: searchText
            )
            .frame(minWidth: 500, idealWidth: 600)
        } detail: {
            // 播放控制视图
            NowPlayingView(player: player, library: library)
                .frame(minWidth: 350, idealWidth: 400)
        }
        .toolbar {
            // 工具栏
            ToolbarItemGroup(placement: .primaryAction) {
                // 添加音乐文件按钮
                Button(action: { presentAddFilesPanel() }) {
                    Image(systemName: "plus")
                }
                .help("添加音乐文件")
                
                // 扫描文件夹按钮
                Button(action: { presentAddDirectoryPanel() }) {
                    Image(systemName: "folder.badge.plus")
                }
                .help("扫描文件夹")
            }
        }

        // 注入环境对象
        .environmentObject(player)
        .environmentObject(library)
    }
    
    /// 处理文件导入
    /// - Parameter result: 文件导入结果
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            // 添加文件到音乐库
            library.addFiles(urls)
        case .failure(let error):
            print("Failed to import files: \(error)")
        }
    }
    
    /// 处理目录导入
    /// - Parameter result: 目录导入结果
    private func handleDirectoryImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            // 扫描目录
            library.scanDirectory(url)
        case .failure(let error):
            print("Failed to import directory: \(error)")
        }
    }
    
    /// 显示添加文件面板
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
    
    /// 显示添加目录面板
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

/// 侧边栏项
/// 表示侧边栏中的选项

enum SidebarItem: Hashable {
    case library    // 音乐库
    case albums     // 专辑
    case artists    // 艺术家
    case playlists  // 播放列表
    case playlist(Playlist)  // 单个播放列表
}
