import Foundation
import AVFoundation
import CryptoKit

struct Track: Identifiable, Equatable, Hashable {
    let id: UUID
    let url: URL
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let artwork: Data?
    let year: String?
    let genre: String?
    let trackNumber: Int?
    
    init(url: URL, title: String, artist: String, album: String, duration: TimeInterval, artwork: Data?, year: String?, genre: String?, trackNumber: Int?) {
        // 使用 URL 的哈希值生成稳定的 UUID
        let urlHash = url.path.md5()
        // 确保哈希值长度足够
        let uuidString = urlHash.padding(toLength: 32, withPad: "0", startingAt: 0)
        // 创建 UUID（使用哈希值的不同部分）
        let uuidParts = [
            uuidString.prefix(8),
            uuidString.dropFirst(8).prefix(4),
            uuidString.dropFirst(12).prefix(4),
            uuidString.dropFirst(16).prefix(4),
            uuidString.dropFirst(20).prefix(12)
        ]
        let formattedUuidString = uuidParts.map(String.init).joined(separator: "-")
        self.id = UUID(uuidString: formattedUuidString) ?? UUID()
        self.url = url
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artwork = artwork
        self.year = year
        self.genre = genre
        self.trackNumber = trackNumber
    }
    
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

extension String {
    func md5() -> String {
        let data = Data(self.utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
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
