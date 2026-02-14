import Foundation
import SwiftUI

// 播放列表数据结构，用于序列化和反序列化
struct PlaylistData: Codable {
    let id: UUID
    let name: String
    let trackIDs: [UUID]
    let createdAt: Date
}

// 专辑模型
struct Album: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let artist: String
    let artwork: Data?
    var tracks: [Track]
    
    var duration: TimeInterval {
        tracks.reduce(0) { $0 + $1.duration }
    }
    
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

// 艺术家模型
struct Artist: Identifiable, Equatable {
    let id = UUID()
    let name: String
    var albums: [Album]
    let artwork: Data?
    
    var tracks: [Track] {
        albums.flatMap { $0.tracks }
    }
}

// 播放列表模型
struct Playlist: Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var tracks: [Track]
    var createdAt: Date
    
    init(name: String, tracks: [Track] = []) {
        self.id = UUID()
        self.name = name
        self.tracks = tracks
        self.createdAt = Date()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// 音乐库模型
class MusicLibrary: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var albums: [Album] = []
    @Published var artists: [Artist] = []
    @Published var playlists: [Playlist] = []
    
    init() {
        loadLibrary()
        loadPlaylists()
    }
    
    // 添加音乐文件
    func addFiles(_ urls: [URL]) {
        let newTracks = urls.compactMap { Track.load(from: $0) }
        // 合并并去重，保持原始顺序
        let existingURLs = Set(self.tracks.map { $0.url })
        let uniqueNewTracks = newTracks.filter { !existingURLs.contains($0.url) }
        self.tracks.append(contentsOf: uniqueNewTracks)
        updateAlbumsAndArtists()
        saveLibrary()
    }
    
    // 扫描目录
    func scanDirectory(_ url: URL) {
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil)
        var newTracks: [Track] = []
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension.lowercased() == "mp3" || 
               fileURL.pathExtension.lowercased() == "flac" ||
               fileURL.pathExtension.lowercased() == "m4a" ||
               fileURL.pathExtension.lowercased() == "wav" {
                if let track = Track.load(from: fileURL) {
                    newTracks.append(track)
                }
            }
        }
        
        // 合并并去重，保持原始顺序
        let existingURLs = Set(self.tracks.map { $0.url })
        let uniqueNewTracks = newTracks.filter { !existingURLs.contains($0.url) }
        self.tracks.append(contentsOf: uniqueNewTracks)
        updateAlbumsAndArtists()
        saveLibrary()
    }
    
    // 保存库到 UserDefaults
    func saveLibrary() {
        let urls = tracks.map { $0.url.absoluteString }
        do {
            let data = try JSONEncoder().encode(urls)
            UserDefaults.standard.set(data, forKey: "musicLibrary")
        } catch {
            print("Error saving tracks: \(error)")
        }
    }
    
    // 从 UserDefaults 加载库
    func loadLibrary() {
        do {
            guard let data = UserDefaults.standard.data(forKey: "musicLibrary") else { return }
            let urls = try JSONDecoder().decode([String].self, from: data)
            tracks = urls.compactMap { URL(string: $0) }.compactMap { Track.load(from: $0) }
            updateAlbumsAndArtists()
        } catch {
            print("Error loading tracks: \(error)")
        }
    }
    
    // 更新专辑和艺术家列表
    func updateAlbumsAndArtists() {
        var albumDict: [String: Album] = [:]
        var artistDict: [String: Artist] = [:]
        
        for track in tracks {
            let albumKey = "\(track.artist)|\(track.album)"
            if var album = albumDict[albumKey] {
                album.tracks.append(track)
                albumDict[albumKey] = album
            } else {
                albumDict[albumKey] = Album(
                    title: track.album,
                    artist: track.artist,
                    artwork: track.artwork,
                    tracks: [track]
                )
            }
        }
        
        // 构建艺人字典
        for (_, album) in albumDict {
            let artistName = album.artist
            if var artist = artistDict[artistName] {
                artist.albums.append(album)
                artistDict[artistName] = artist
            } else {
                // 尝试为艺人查找同名图片
                var artistArtwork: Data? = nil
                // 使用专辑中的第一首歌曲来查找艺人图片
                if let firstTrack = album.tracks.first {
                    artistArtwork = Track.findArtistImage(from: firstTrack.url, artistName: artistName)
                }
                
                artistDict[artistName] = Artist(
                    name: artistName,
                    albums: [album],
                    artwork: artistArtwork
                )
            }
        }
        
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
    
    // 移除专辑
    func removeAlbum(_ album: Album) {
        // 从 tracks 中移除该专辑的所有歌曲
        tracks = tracks.filter { $0.artist != album.artist || $0.album != album.title }
        // 更新专辑和艺术家列表
        updateAlbumsAndArtists()
        saveLibrary()
    }
    
    // 移除艺人
    func removeArtist(_ artist: Artist) {
        // 从 tracks 中移除该艺人的所有歌曲
        tracks = tracks.filter { $0.artist != artist.name }
        // 更新专辑和艺术家列表
        updateAlbumsAndArtists()
        saveLibrary()
    }
    
    // 保存播放列表
    func savePlaylists() {
        let playlistData = playlists.map { playlist in
            PlaylistData(
                id: playlist.id,
                name: playlist.name,
                trackIDs: playlist.tracks.map { $0.id },
                createdAt: playlist.createdAt
            )
        }
        
        do {
            let data = try JSONEncoder().encode(playlistData)
            UserDefaults.standard.set(data, forKey: "playlists")
        } catch {
            print("Error saving playlists: \(error)")
        }
    }
    
    // 加载播放列表
    func loadPlaylists() {
        do {
            guard let data = UserDefaults.standard.data(forKey: "playlists") else { return }
            let playlistData = try JSONDecoder().decode([PlaylistData].self, from: data)
            
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
    
    // 创建播放列表
    func createPlaylist(name: String, tracks: [Track] = []) {
        let playlist = Playlist(name: name, tracks: tracks)
        playlists.append(playlist)
        savePlaylists()
    }
    
    // 删除播放列表
    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        savePlaylists()
    }
    
    // 更新播放列表
    func updatePlaylist(_ playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index] = playlist
            savePlaylists()
        }
    }
    
    // 添加歌曲到播放列表
    func addTrackToPlaylist(_ track: Track, playlist: Playlist) {
        if var updatedPlaylist = playlists.first(where: { $0.id == playlist.id }) {
            if !updatedPlaylist.tracks.contains(where: { $0.id == track.id }) {
                updatedPlaylist.tracks.append(track)
                updatePlaylist(updatedPlaylist)
            }
        }
    }
    
    // 从播放列表中移除歌曲
    func removeTrackFromPlaylist(_ track: Track, playlist: Playlist) {
        if var updatedPlaylist = playlists.first(where: { $0.id == playlist.id }) {
            updatedPlaylist.tracks.removeAll { $0.id == track.id }
            updatePlaylist(updatedPlaylist)
        }
    }
    
    // 移除歌曲
    func removeTrack(_ track: Track) {
        tracks.removeAll { $0.id == track.id }
        updateAlbumsAndArtists()
        saveLibrary()
    }
    
    func search(query: String) -> [Track] {
        guard !query.isEmpty else { return tracks }
        let lowerQuery = query.lowercased()
        return tracks.filter {
            $0.title.lowercased().contains(lowerQuery) ||
            $0.artist.lowercased().contains(lowerQuery) ||
            $0.album.lowercased().contains(lowerQuery)
        }
    }
}