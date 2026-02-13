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
                // 加载 commonMetadata
                metadata = try await asset.load(.commonMetadata)
                
                // 打印加载的元数据数量
                print("Loaded \(metadata.count) metadata items for file: \(url.lastPathComponent)")
            } catch {
                print("Error loading metadata: \(error)")
            }
            metadataSemaphore.signal()
        }
        metadataSemaphore.wait()
        
        // 处理 metadata
        print("Processing metadata for file: \(url.lastPathComponent)")
        print("Total metadata items: \(metadata.count)")
        
        for (index, item) in metadata.enumerated() {
            // 打印每个元数据项的详细信息
            print("\nMetadata item \(index):")
            if let commonKey = item.commonKey?.rawValue {
                print("  Common key: \(commonKey)")
            }
            if let key = item.key {
                print("  Key: \(key)")
                print("  Key type: \(type(of: key))")
                if let keyStr = key as? String {
                    print("  Key as string: \(keyStr)")
                    print("  Key lowercase: \(keyStr.lowercased())")
                }
            }
            
            // 尝试读取值
            let valueSemaphore = DispatchSemaphore(value: 0)
            Task {
                do {
                    if let value = try await item.load(.stringValue) {
                        print("  Value: \(value)")
                    }
                } catch {
                    print("  Error loading value: \(error)")
                }
                valueSemaphore.signal()
            }
            valueSemaphore.wait()
            
            // 优先使用 commonKey
            if let commonKey = item.commonKey?.rawValue {
                switch commonKey {
                case "title":
                    let semaphore = DispatchSemaphore(value: 0)
                    Task {
                        do {
                            if let value = try await item.load(.stringValue) {
                                title = value
                                print("  Title from commonKey: \(value)")
                            }
                        } catch {
                            print("  Error loading title: \(error)")
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
                                print("  Artist from commonKey: \(value)")
                            }
                        } catch {
                            print("  Error loading artist: \(error)")
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
                                print("  Album from commonKey: \(value)")
                            }
                        } catch {
                            print("  Error loading album: \(error)")
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
                                print("  Artwork from commonKey: \(value.count) bytes")
                            }
                        } catch {
                            print("  Error loading artwork: \(error)")
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
                                print("  Year from commonKey: \(value)")
                            }
                        } catch {
                            print("  Error loading year: \(error)")
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
                                print("  Genre from commonKey: \(value)")
                            }
                        } catch {
                            print("  Error loading genre: \(error)")
                        }
                        semaphore.signal()
                    }
                    semaphore.wait()
                default:
                    break
                }
            } else {
                // 处理非 commonKey 的 metadata
                let semaphore = DispatchSemaphore(value: 0)
                Task {
                    do {
                        if let value = try await item.load(.stringValue) {
                            print("  Processing non-commonKey item with value: \(value)")
                            
                            // 尝试匹配标题
                            if let key = item.key as? String {
                                if key.lowercased().contains("title") || key.lowercased().contains("name") || key == "©nam" {
                                    title = value
                                    print("  Title from non-commonKey: \(value)")
                                }
                                
                                // 尝试匹配艺术家
                                if key.lowercased().contains("artist") || key.lowercased().contains("author") || key == "©art" || key == "作者" || key == "Authors" || key == "Author" {
                                    artist = value
                                    print("  Artist from non-commonKey: \(value)")
                                }
                                
                                // 尝试匹配专辑
                                if key.lowercased().contains("album") || key == "©alb" || key == "Album" || key == "专辑" {
                                    album = value
                                    print("  Album from non-commonKey: \(value)")
                                }
                                // 尝试直接匹配所有可能的专辑字段，不管大小写
                                let lowercaseKey = key.lowercased()
                                if lowercaseKey == "album" || lowercaseKey == "©alb" || lowercaseKey == "专辑" {
                                    album = value
                                    print("  Album from direct match: \(value)")
                                }
                                
                                // 尝试匹配年份
                                if key.lowercased().contains("year") || key.lowercased().contains("date") || key == "©day" {
                                    year = value
                                    print("  Year from non-commonKey: \(value)")
                                }
                                
                                // 尝试匹配流派
                                if key.lowercased().contains("genre") || key == "©gen" {
                                    genre = value
                                    print("  Genre from non-commonKey: \(value)")
                                }
                            }
                        }
                    } catch {
                        print("  Error processing non-commonKey item: \(error)")
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            }
        }
        
        // 打印当前的艺术家和专辑信息
        print("\nCurrent metadata status:")
        print("  Title: \(title)")
        print("  Artist: \(artist)")
        print("  Album: \(album)")
        print("  Genre: \(genre ?? "Unknown")")
        print("  Year: \(year ?? "Unknown")")
        
        // 如果从元数据中没有获取到艺术家信息，尝试从文件名中提取
        if artist == "Unknown Artist" {
            let fileName = url.deletingPathExtension().lastPathComponent
            print("Trying to extract artist from filename: \(fileName)")
            
            // 尝试匹配 "艺术家 - 歌曲" 格式
            let artistSongRegex = #"(.+?)\s*-\s*(.+)"#
            if let match = fileName.range(of: artistSongRegex, options: .regularExpression) {
                let matchString = String(fileName[match])
                if let separatorIndex = matchString.firstIndex(of: "-") {
                    var extractedArtist = String(matchString[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
                    
                    // 去除艺术家名称中的前缀数字（如 "01. Richard Clayderman" 中的 "01."）
                    let prefixNumberRegex = #"^\d+\.\s*"#
                    if let prefixMatch = extractedArtist.range(of: prefixNumberRegex, options: .regularExpression) {
                        extractedArtist = String(extractedArtist[prefixMatch.upperBound...]).trimmingCharacters(in: .whitespaces)
                        print("Removed prefix from artist: \(extractedArtist)")
                    }
                    
                    artist = extractedArtist
                    print("Artist extracted from filename: \(extractedArtist)")
                }
            }
        }
        
        // 如果从元数据中没有获取到专辑信息，尝试从文件路径中提取
        if album == "Unknown Album" {
            print("Trying to extract album from file path")
            
            // 获取文件路径的目录结构
            let currentDir = url.deletingLastPathComponent()
            let currentDirName = currentDir.lastPathComponent
            let parentDir = currentDir.deletingLastPathComponent().lastPathComponent
            let grandparentDir = currentDir.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
            
            print("Directory structure:")
            print("  Current directory: \(currentDirName)")
            print("  Parent directory: \(parentDir)")
            print("  Grandparent directory: \(grandparentDir)")
            
            // 优先尝试使用上一级目录作为专辑名称（如果不是 CD 目录）
            if !parentDir.isEmpty && !parentDir.hasPrefix("CD ") {
                album = parentDir
                print("Album extracted from parent directory: \(parentDir)")
            } else if !grandparentDir.isEmpty {
                // 如果上一级是 CD 目录，使用再上一级目录
                album = grandparentDir
                print("Album extracted from grandparent directory: \(grandparentDir)")
            } else if !currentDirName.isEmpty {
                // 最后使用当前目录
                album = currentDirName
                print("Album extracted from current directory: \(currentDirName)")
            }
        }
        
        // 打印最终的艺术家和专辑信息
        print("Final artist: \(artist)")
        print("Final album: \(album)")
        
        // 如果没有找到内置封面，尝试从文件系统加载封面
        if artwork == nil {
            artwork = findCoverImage(from: url)
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
    
    // 在当前目录及上级目录查找封面图片
    private static func findCoverImage(from url: URL) -> Data? {
        let fileManager = FileManager.default
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp"]
        let coverNames = ["cover", "folder", "front", "album"]
        
        // 从当前文件所在目录开始，向上查找
        var currentDirectory = url.deletingLastPathComponent()
        
        // 最多向上查找 5 级目录
        for _ in 0..<5 {
            // 尝试在当前目录查找封面图片
            for coverName in coverNames {
                for ext in imageExtensions {
                    let coverURL = currentDirectory.appendingPathComponent("\(coverName).\(ext)")
                    if fileManager.fileExists(atPath: coverURL.path) {
                        if let data = try? Data(contentsOf: coverURL) {
                            return data
                        }
                    }
                }
            }
            
            // 尝试在当前目录查找任何图片文件
            let enumerator = fileManager.enumerator(at: currentDirectory, includingPropertiesForKeys: nil)
            while let fileURL = enumerator?.nextObject() as? URL {
                if imageExtensions.contains(fileURL.pathExtension.lowercased()) {
                    if let data = try? Data(contentsOf: fileURL) {
                        return data
                    }
                }
            }
            
            // 向上一级目录
            let parentDirectory = currentDirectory.deletingLastPathComponent()
            if parentDirectory == currentDirectory { // 已经到达根目录
                break
            }
            currentDirectory = parentDirectory
        }
        
        return nil
    }
}
