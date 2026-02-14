//
//  MusicLibrary.swift
//  XMusic
//
//  音乐库模型
//

import Foundation
import SwiftUI

/// 播放列表数据结构，用于序列化和反序列化
/// 存储播放列表的基本信息和歌曲 ID
struct PlaylistData: Codable {
    /// 播放列表 ID
    let id: UUID
    /// 播放列表名称
    let name: String
    /// 歌曲 ID 列表
    let trackIDs: [UUID]
    /// 创建时间
    let createdAt: Date
}

/// 专辑模型
/// 表示一张专辑，包含标题、艺术家、封面、歌曲等信息
struct Album: Identifiable, Equatable {
    /// 唯一标识符
    let id = UUID()
    /// 专辑标题
    let title: String
    /// 艺术家名称
    let artist: String
    /// 封面图片数据
    let artwork: Data?
    /// 专辑中的歌曲列表
    var tracks: [Track]
    
    /// 专辑总时长（秒）
    var duration: TimeInterval {
        tracks.reduce(0) { $0 + $1.duration }
    }
    
    /// 格式化的专辑总时长字符串
    /// - Returns: 格式化的时长字符串（如 "1:23:45" 或 "45:30"）
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, remainingMinutes, Int(duration) % 60)
        }
        return String(format: "%d:%02d", minutes, Int(duration) % 60)
    }
}

/// 艺术家模型
/// 表示一位艺术家，包含名称、专辑、图片等信息
struct Artist: Identifiable, Equatable {
    /// 唯一标识符
    let id = UUID()
    /// 艺术家名称
    let name: String
    /// 艺术家的专辑列表
    var albums: [Album]
    /// 艺术家图片数据
    let artwork: Data?
    
    /// 艺术家的所有歌曲列表
    /// - Returns: 艺术家的所有歌曲
    var tracks: [Track] {
        albums.flatMap { $0.tracks }
    }
}

/// 播放列表模型
/// 表示一个播放列表，包含名称、歌曲、创建时间等信息
struct Playlist: Identifiable, Equatable, Hashable {
    /// 唯一标识符
    var id: UUID
    /// 播放列表名称
    var name: String
    /// 播放列表中的歌曲列表
    var tracks: [Track]
    /// 创建时间
    var createdAt: Date
    
    /// 初始化方法
    /// - Parameters:
    ///   - name: 播放列表名称
    ///   - tracks: 播放列表中的歌曲列表（默认为空）
    init(name: String, tracks: [Track] = []) {
        self.id = UUID()
        self.name = name
        self.tracks = tracks
        self.createdAt = Date()
    }
    
    /// 生成哈希值
    /// - Parameter hasher: 哈希器
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// 音乐库模型
/// 管理音乐库的核心数据，包括歌曲、专辑、艺术家和播放列表
class MusicLibrary: ObservableObject {
    /// 歌曲列表
    @Published var tracks: [Track] = []
    /// 专辑列表
    @Published var albums: [Album] = []
    /// 艺术家列表
    @Published var artists: [Artist] = []
    /// 播放列表列表
    @Published var playlists: [Playlist] = []
    
    /// 初始化方法
    /// 加载音乐库和播放列表
    init() {
        loadLibrary()
        loadPlaylists()
    }
    
    /// 添加音乐文件
    /// - Parameter urls: 音乐文件的 URL 列表
    func addFiles(_ urls: [URL]) {
        // 加载音乐文件
        let newTracks = urls.compactMap { Track.load(from: $0) }
        // 合并并去重，保持原始顺序
        let existingURLs = Set(self.tracks.map { $0.url })
        let uniqueNewTracks = newTracks.filter { !existingURLs.contains($0.url) }
        self.tracks.append(contentsOf: uniqueNewTracks)
        // 更新专辑和艺术家列表
        updateAlbumsAndArtists()
        // 保存音乐库
        saveLibrary()
    }
    
    /// 扫描目录
    /// - Parameter url: 要扫描的目录 URL
    func scanDirectory(_ url: URL) {
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil)
        var newTracks: [Track] = []
        
        // 遍历目录中的文件
        while let fileURL = enumerator?.nextObject() as? URL {
            // 检查文件扩展名
            if fileURL.pathExtension.lowercased() == "mp3" || 
               fileURL.pathExtension.lowercased() == "flac" ||
               fileURL.pathExtension.lowercased() == "m4a" ||
               fileURL.pathExtension.lowercased() == "wav" {
                // 加载音乐文件
                if let track = Track.load(from: fileURL) {
                    newTracks.append(track)
                }
            }
        }
        
        // 合并并去重，保持原始顺序
        let existingURLs = Set(self.tracks.map { $0.url })
        let uniqueNewTracks = newTracks.filter { !existingURLs.contains($0.url) }
        self.tracks.append(contentsOf: uniqueNewTracks)
        // 更新专辑和艺术家列表
        updateAlbumsAndArtists()
        // 保存音乐库
        saveLibrary()
    }
    
    /// 保存库到 UserDefaults
    func saveLibrary() {
        // 提取歌曲 URL
        let urls = tracks.map { $0.url.absoluteString }
        do {
            // 编码为 JSON
            let data = try JSONEncoder().encode(urls)
            // 保存到 UserDefaults
            UserDefaults.standard.set(data, forKey: "musicLibrary")
        } catch {
            print("Error saving tracks: \(error)")
        }
    }
    
    /// 从 UserDefaults 加载库
    func loadLibrary() {
        do {
            // 从 UserDefaults 加载数据
            guard let data = UserDefaults.standard.data(forKey: "musicLibrary") else { return }
            // 解码 JSON
            let urls = try JSONDecoder().decode([String].self, from: data)
            // 加载歌曲
            tracks = urls.compactMap { URL(string: $0) }.compactMap { Track.load(from: $0) }
            // 更新专辑和艺术家列表
            updateAlbumsAndArtists()
        } catch {
            print("Error loading tracks: \(error)")
        }
    }
    
    /// 更新专辑和艺术家列表
    func updateAlbumsAndArtists() {
        // 构建专辑字典
        var albumDict: [String: Album] = [:]
        // 构建艺术家字典
        var artistDict: [String: Artist] = [:]
        
        // 遍历歌曲，构建专辑
        for track in tracks {
            // 生成专辑键
            let albumKey = "\(track.artist)|\(track.album)"
            if var album = albumDict[albumKey] {
                // 专辑已存在，添加歌曲
                album.tracks.append(track)
                albumDict[albumKey] = album
            } else {
                // 专辑不存在，创建新专辑
                albumDict[albumKey] = Album(
                    title: track.album,
                    artist: track.artist,
                    artwork: track.artwork,
                    tracks: [track]
                )
            }
        }
        
        // 构建艺术家字典
        for (_, album) in albumDict {
            let artistName = album.artist
            if var artist = artistDict[artistName] {
                // 艺术家已存在，添加专辑
                artist.albums.append(album)
                artistDict[artistName] = artist
            } else {
                // 尝试为艺人查找同名图片
                var artistArtwork: Data? = nil
                // 使用专辑中的第一首歌曲来查找艺人图片
                if let firstTrack = album.tracks.first {
                    artistArtwork = Track.findArtistImage(from: firstTrack.url, artistName: artistName)
                }
                
                // 艺术家不存在，创建新艺术家
                artistDict[artistName] = Artist(
                    name: artistName,
                    albums: [album],
                    artwork: artistArtwork
                )
            }
        }
        
        // 转换为数组并排序
        albums = Array(albumDict.values).sorted { $0.title < $1.title }
        artists = Array(artistDict.values).sorted { $0.name < $1.name }
        
        // 打印统计信息
        print("Updated albums and artists:")
        print("Total tracks: \(tracks.count)")
        print("Total albums: \(albums.count)")
        print("Total artists: \(artists.count)")
        for artist in artists {
            print("Artist: \(artist.name), Albums: \(artist.albums.count), Tracks: \(artist.tracks.count)")
        }
    }
    
    /// 移除专辑
    /// - Parameter album: 要移除的专辑
    func removeAlbum(_ album: Album) {
        // 从 tracks 中移除该专辑的所有歌曲
        tracks = tracks.filter { $0.artist != album.artist || $0.album != album.title }
        // 更新专辑和艺术家列表
        updateAlbumsAndArtists()
        // 保存音乐库
        saveLibrary()
    }
    
    /// 移除艺人
    /// - Parameter artist: 要移除的艺人
    func removeArtist(_ artist: Artist) {
        // 从 tracks 中移除该艺人的所有歌曲
        tracks = tracks.filter { $0.artist != artist.name }
        // 更新专辑和艺术家列表
        updateAlbumsAndArtists()
        // 保存音乐库
        saveLibrary()
    }
    
    /// 保存播放列表
    func savePlaylists() {
        // 转换为 PlaylistData
        let playlistData = playlists.map { playlist in
            PlaylistData(
                id: playlist.id,
                name: playlist.name,
                trackIDs: playlist.tracks.map { $0.id },
                createdAt: playlist.createdAt
            )
        }
        
        do {
            // 编码为 JSON
            let data = try JSONEncoder().encode(playlistData)
            // 保存到 UserDefaults
            UserDefaults.standard.set(data, forKey: "playlists")
        } catch {
            print("Error saving playlists: \(error)")
        }
    }
    
    /// 加载播放列表
    func loadPlaylists() {
        do {
            // 从 UserDefaults 加载数据
            guard let data = UserDefaults.standard.data(forKey: "playlists") else { return }
            // 解码 JSON
            let playlistData = try JSONDecoder().decode([PlaylistData].self, from: data)
            
            // 转换为 Playlist
            playlists = playlistData.map { data in
                let playlistTracks = tracks.filter { data.trackIDs.contains($0.id) }
                var playlist = Playlist(name: data.name, tracks: playlistTracks)
                playlist.id = data.id
                playlist.createdAt = data.createdAt
                return playlist
            }
        } catch {
            print("Error loading playlists: \(error)")
        }
    }
    
    /// 创建播放列表
    /// - Parameters:
    ///   - name: 播放列表名称
    ///   - tracks: 播放列表中的歌曲列表（默认为空）
    func createPlaylist(name: String, tracks: [Track] = []) {
        // 创建新播放列表
        let playlist = Playlist(name: name, tracks: tracks)
        // 添加到播放列表列表
        playlists.append(playlist)
        // 保存播放列表
        savePlaylists()
    }
    
    /// 删除播放列表
    /// - Parameter playlist: 要删除的播放列表
    func deletePlaylist(_ playlist: Playlist) {
        // 从播放列表列表中移除
        playlists.removeAll { $0.id == playlist.id }
        // 保存播放列表
        savePlaylists()
    }
    
    /// 更新播放列表
    /// - Parameter playlist: 要更新的播放列表
    func updatePlaylist(_ playlist: Playlist) {
        // 查找播放列表索引
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            // 更新播放列表
            playlists[index] = playlist
            // 保存播放列表
            savePlaylists()
        }
    }
    
    /// 添加歌曲到播放列表
    /// - Parameters:
    ///   - track: 要添加的歌曲
    ///   - playlist: 目标播放列表
    func addTrackToPlaylist(_ track: Track, playlist: Playlist) {
        // 查找播放列表
        if var updatedPlaylist = playlists.first(where: { $0.id == playlist.id }) {
            // 检查歌曲是否已存在
            if !updatedPlaylist.tracks.contains(where: { $0.id == track.id }) {
                // 添加歌曲
                updatedPlaylist.tracks.append(track)
                // 更新播放列表
                updatePlaylist(updatedPlaylist)
            }
        }
    }
    
    /// 从播放列表中移除歌曲
    /// - Parameters:
    ///   - track: 要移除的歌曲
    ///   - playlist: 目标播放列表
    func removeTrackFromPlaylist(_ track: Track, playlist: Playlist) {
        // 查找播放列表
        if var updatedPlaylist = playlists.first(where: { $0.id == playlist.id }) {
            // 移除歌曲
            updatedPlaylist.tracks.removeAll { $0.id == track.id }
            // 更新播放列表
            updatePlaylist(updatedPlaylist)
        }
    }
    
    /// 移除歌曲
    /// - Parameter track: 要移除的歌曲
    func removeTrack(_ track: Track) {
        // 从歌曲列表中移除
        tracks.removeAll { $0.id == track.id }
        // 更新专辑和艺术家列表
        updateAlbumsAndArtists()
        // 保存音乐库
        saveLibrary()
    }
    
    /// 搜索歌曲
    /// - Parameter query: 搜索关键词
    /// - Returns: 搜索结果
    func search(query: String) -> [Track] {
        // 如果关键词为空，返回所有歌曲
        guard !query.isEmpty else { return tracks }
        // 转换为小写
        let lowerQuery = query.lowercased()
        // 过滤歌曲
        return tracks.filter {
            $0.title.lowercased().contains(lowerQuery) ||
            $0.artist.lowercased().contains(lowerQuery) ||
            $0.album.lowercased().contains(lowerQuery)
        }
    }
}