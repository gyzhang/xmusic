import Foundation
import Combine

class MusicLibrary: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var albums: [Album] = []
    @Published var artists: [Artist] = []
    @Published var playlists: [Playlist] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadLibrary()
    }
    
    func scanDirectory(_ url: URL) {
        isScanning = true
        scanProgress = 0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let fileManager = FileManager.default
            let supportedExtensions = AudioPlayer.supportedAudioExtensions()
            
            var newTracks: [Track] = []
            
            if let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) {
                var files: [URL] = []
                for case let fileURL as URL in enumerator {
                    let ext = fileURL.pathExtension.lowercased()
                    if supportedExtensions.contains(ext) {
                        files.append(fileURL)
                    }
                }
                
                let totalFiles = files.count
                for (index, fileURL) in files.enumerated() {
                    if let track = Track.load(from: fileURL) {
                        newTracks.append(track)
                    }
                    
                    DispatchQueue.main.async {
                        self.scanProgress = Double(index + 1) / Double(totalFiles)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.tracks.append(contentsOf: newTracks)
                self.tracks = Array(Set(self.tracks)).sorted { $0.title < $1.title }
                self.updateAlbumsAndArtists()
                self.isScanning = false
                self.saveLibrary()
            }
        }
    }
    
    func addFiles(_ urls: [URL]) {
        var newTracks: [Track] = []
        for url in urls {
            if let track = Track.load(from: url) {
                newTracks.append(track)
            }
        }
        
        tracks.append(contentsOf: newTracks)
        tracks = Array(Set(tracks)).sorted { $0.title < $1.title }
        updateAlbumsAndArtists()
        saveLibrary()
    }
    
    func removeTrack(_ track: Track) {
        tracks.removeAll { $0.id == track.id }
        updateAlbumsAndArtists()
        saveLibrary()
    }
    
    func createPlaylist(name: String, tracks: [Track] = []) {
        let playlist = Playlist(name: name, tracks: tracks)
        playlists.append(playlist)
        saveLibrary()
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        saveLibrary()
    }
    
    func addTrackToPlaylist(_ track: Track, playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            var updatedPlaylist = playlists[index]
            if !updatedPlaylist.tracks.contains(where: { $0.id == track.id }) {
                updatedPlaylist.tracks.append(track)
                playlists[index] = updatedPlaylist
                saveLibrary()
            }
        }
    }
    
    func removeTrackFromPlaylist(_ track: Track, playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            var updatedPlaylist = playlists[index]
            updatedPlaylist.tracks.removeAll { $0.id == track.id }
            playlists[index] = updatedPlaylist
            saveLibrary()
        }
    }
    
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
            
            if var artist = artistDict[track.artist] {
                if !artist.albums.contains(where: { $0.title == track.album }) {
                    artist.albums.append(albumDict[albumKey]!)
                }
                artistDict[track.artist] = artist
            } else {
                artistDict[track.artist] = Artist(
                    name: track.artist,
                    albums: [albumDict[albumKey]!]
                )
            }
        }
        
        albums = Array(albumDict.values).sorted { $0.title < $1.title }
        artists = Array(artistDict.values).sorted { $0.name < $1.name }
    }
    
    private func saveLibrary() {
        if let encoded = try? JSONEncoder().encode(tracks.map { $0.url.absoluteString }) {
            UserDefaults.standard.set(encoded, forKey: "musicLibrary")
        }
    }
    
    private func loadLibrary() {
        guard let data = UserDefaults.standard.data(forKey: "musicLibrary"),
              let urls = try? JSONDecoder().decode([String].self, from: data) else {
            return
        }
        
        var loadedTracks: [Track] = []
        for urlString in urls {
            if let url = URL(string: urlString),
               let track = Track.load(from: url) {
                loadedTracks.append(track)
            }
        }
        
        tracks = loadedTracks
        updateAlbumsAndArtists()
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

struct Artist: Identifiable, Equatable {
    let id = UUID()
    let name: String
    var albums: [Album]
    
    var tracks: [Track] {
        albums.flatMap { $0.tracks }
    }
}

struct Playlist: Identifiable, Equatable, Hashable {
    let id = UUID()
    var name: String
    var tracks: [Track]
    let createdAt: Date
    
    init(name: String, tracks: [Track] = []) {
        self.name = name
        self.tracks = tracks
        self.createdAt = Date()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
