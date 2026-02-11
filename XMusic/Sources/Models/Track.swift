import Foundation
import AVFoundation

struct Track: Identifiable, Equatable, Hashable {
    let id = UUID()
    let url: URL
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let artwork: Data?
    let year: String?
    let genre: String?
    let trackNumber: Int?
    
    var fileName: String {
        url.deletingPathExtension().lastPathComponent
    }
    
    var fileExtension: String {
        url.pathExtension.lowercased()
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Track {
    static func load(from url: URL) -> Track? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        
        let asset = AVURLAsset(url: url)
        
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var album = "Unknown Album"
        var artwork: Data?
        var year: String?
        var genre: String?
        let trackNumber: Int? = nil
        
        // 同步加载 metadata
        var metadata: [AVMetadataItem] = []
        let metadataSemaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                metadata = try await asset.load(.commonMetadata)
            } catch {
                print("Error loading metadata: \(error)")
            }
            metadataSemaphore.signal()
        }
        metadataSemaphore.wait()
        
        // 处理 metadata
        for item in metadata {
            switch item.commonKey?.rawValue {
            case "title":
                let semaphore = DispatchSemaphore(value: 0)
                Task {
                    do {
                        if let value = try await item.load(.stringValue) {
                            title = value
                        }
                    } catch {
                        print("Error loading title: \(error)")
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            case "artist":
                let semaphore = DispatchSemaphore(value: 0)
                Task {
                    do {
                        if let value = try await item.load(.stringValue) {
                            artist = value
                        }
                    } catch {
                        print("Error loading artist: \(error)")
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            case "albumName":
                let semaphore = DispatchSemaphore(value: 0)
                Task {
                    do {
                        if let value = try await item.load(.stringValue) {
                            album = value
                        }
                    } catch {
                        print("Error loading album: \(error)")
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            case "artwork":
                let semaphore = DispatchSemaphore(value: 0)
                Task {
                    do {
                        if let value = try await item.load(.dataValue) {
                            artwork = value
                        }
                    } catch {
                        print("Error loading artwork: \(error)")
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            case "creationDate":
                let semaphore = DispatchSemaphore(value: 0)
                Task {
                    do {
                        if let value = try await item.load(.stringValue) {
                            year = value
                        }
                    } catch {
                        print("Error loading year: \(error)")
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            case "type":
                let semaphore = DispatchSemaphore(value: 0)
                Task {
                    do {
                        if let value = try await item.load(.stringValue) {
                            genre = value
                        }
                    } catch {
                        print("Error loading genre: \(error)")
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            default:
                break
            }
        }
        
        // 同步加载 duration
        var duration: TimeInterval = 0
        let durationSemaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                let time = try await asset.load(.duration)
                duration = time.seconds.isFinite ? time.seconds : 0
            } catch {
                print("Error loading duration: \(error)")
            }
            durationSemaphore.signal()
        }
        durationSemaphore.wait()
        
        return Track(
            url: url,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            artwork: artwork,
            year: year,
            genre: genre,
            trackNumber: trackNumber
        )
    }
}
