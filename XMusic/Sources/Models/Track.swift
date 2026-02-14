//
//  Track.swift
//  XMusic
//
//  音乐轨道模型
//

import Foundation
import AVFoundation
import CryptoKit

/// 音乐轨道模型
/// 表示一首音乐，包含标题、艺术家、专辑、时长等信息
struct Track: Identifiable, Equatable, Hashable {
    /// 唯一标识符
    let id: UUID
    /// 音乐文件的 URL
    let url: URL
    /// 音乐标题
    let title: String
    /// 艺术家名称
    let artist: String
    /// 专辑名称
    let album: String
    /// 音乐时长（秒）
    let duration: TimeInterval
    /// 封面图片数据
    let artwork: Data?
    /// 发行年份
    let year: String?
    /// 音乐流派
    let genre: String?
    /// 音轨编号
    let trackNumber: Int?
    
    /// 初始化方法
    /// - Parameters:
    ///   - url: 音乐文件的 URL
    ///   - title: 音乐标题
    ///   - artist: 艺术家名称
    ///   - album: 专辑名称
    ///   - duration: 音乐时长（秒）
    ///   - artwork: 封面图片数据
    ///   - year: 发行年份
    ///   - genre: 音乐流派
    ///   - trackNumber: 音轨编号
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
    
    /// 文件名（不包含扩展名）
    var fileName: String {
        url.deletingPathExtension().lastPathComponent
    }
    
    /// 文件扩展名（小写）
    var fileExtension: String {
        url.pathExtension.lowercased()
    }
    
    /// 格式化的时长字符串（如 "3:45"）
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// 比较两个 Track 是否相等
    /// - Parameters:
    ///   - lhs: 左侧的 Track
    ///   - rhs: 右侧的 Track
    /// - Returns: 是否相等
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
    
    /// 生成哈希值
    /// - Parameter hasher: 哈希器
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// String 扩展，添加 MD5 哈希方法
/// 用于生成稳定的 UUID

extension String {
    /// 生成 MD5 哈希字符串
    /// - Returns: MD5 哈希字符串
    func md5() -> String {
        let data = Data(self.utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

/// Track 扩展，添加加载方法

extension Track {
    /// 从 URL 加载音乐轨道
    /// - Parameter url: 音乐文件的 URL
    /// - Returns: 加载的 Track 对象，失败则返回 nil
    static func load(from url: URL) -> Track? {
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        
        // 创建 AVURLAsset 对象
        let asset = AVURLAsset(url: url)
        
        // 初始化默认值
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
            } catch {
                // 静默处理错误
            }
            metadataSemaphore.signal()
        }
        metadataSemaphore.wait()
        
        // 处理 metadata
        for item in metadata {
            // 优先使用 commonKey
            if let commonKey = item.commonKey?.rawValue {
                switch commonKey {
                case "title":
                    loadMetadataValue(item) { value in
                        title = value
                    }
                case "artist":
                    loadMetadataValue(item) { value in
                        artist = value
                    }
                case "albumName":
                    loadMetadataValue(item) { value in
                        album = value
                    }
                case "artwork":
                    let semaphore = DispatchSemaphore(value: 0)
                    Task {
                        do {
                            if let value = try await item.load(.dataValue) {
                                artwork = value
                            }
                        } catch {
                            // 静默处理错误
                        }
                        semaphore.signal()
                    }
                    semaphore.wait()
                case "creationDate":
                    loadMetadataValue(item) { value in
                        year = value
                    }
                case "type":
                    loadMetadataValue(item) { value in
                        genre = value
                    }
                default:
                    break
                }
            } else {
                // 处理非 commonKey 的 metadata
                let semaphore = DispatchSemaphore(value: 0)
                Task {
                    do {
                        if let value = try await item.load(.stringValue),
                           let key = item.key as? String {
                            processMetadataKey(key, value: value, &title, &artist, &album, &year, &genre)
                        }
                    } catch {
                        // 静默处理错误
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            }
        }
        
        // 如果从元数据中没有获取到艺术家信息，尝试从文件名中提取
        if artist == "Unknown Artist" {
            extractArtistFromFilename(url, &artist)
        }
        
        // 如果从元数据中没有获取到专辑信息，尝试从文件路径中提取
        if album == "Unknown Album" {
            extractAlbumFromPath(url, &album)
        }
        
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
                // 静默处理错误
            }
            durationSemaphore.signal()
        }
        durationSemaphore.wait()
        
        // 创建并返回 Track 对象
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
    
    /// 加载元数据值
    /// - Parameters:
    ///   - item: 元数据项
    ///   - completion: 完成回调
    private static func loadMetadataValue(_ item: AVMetadataItem, completion: @escaping (String) -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                if let value = try await item.load(.stringValue) {
                    completion(value)
                }
            } catch {
                // 静默处理错误
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    /// 处理元数据键
    /// - Parameters:
    ///   - key: 元数据键
    ///   - value: 元数据值
    ///   - title: 标题（inout）
    ///   - artist: 艺术家（inout）
    ///   - album: 专辑（inout）
    ///   - year: 年份（inout）
    ///   - genre: 流派（inout）
    private static func processMetadataKey(_ key: String, value: String, _ title: inout String, _ artist: inout String, _ album: inout String, _ year: inout String?, _ genre: inout String?) {
        let lowercaseKey = key.lowercased()
        
        // 尝试匹配标题
        if lowercaseKey.contains("title") || lowercaseKey.contains("name") || key == "©nam" {
            title = value
        }
        
        // 尝试匹配艺术家
        if lowercaseKey.contains("artist") || lowercaseKey.contains("author") || key == "©art" || key == "作者" || key == "Authors" || key == "Author" {
            artist = value
        }
        
        // 尝试匹配专辑
        if lowercaseKey.contains("album") || key == "©alb" || key == "Album" || key == "专辑" {
            album = value
        }
        
        // 尝试匹配年份
        if lowercaseKey.contains("year") || lowercaseKey.contains("date") || key == "©day" {
            year = value
        }
        
        // 尝试匹配流派
        if lowercaseKey.contains("genre") || key == "©gen" {
            genre = value
        }
    }
    
    /// 从文件名提取艺术家信息
    /// - Parameters:
    ///   - url: 音乐文件的 URL
    ///   - artist: 艺术家名称（inout）
    private static func extractArtistFromFilename(_ url: URL, _ artist: inout String) {
        let fileName = url.deletingPathExtension().lastPathComponent
        
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
                }
                
                artist = extractedArtist
            }
        }
    }
    
    /// 从文件路径提取专辑信息
    /// - Parameters:
    ///   - url: 音乐文件的 URL
    ///   - album: 专辑名称（inout）
    private static func extractAlbumFromPath(_ url: URL, _ album: inout String) {
        // 获取文件路径的目录结构
        let currentDir = url.deletingLastPathComponent()
        let currentDirName = currentDir.lastPathComponent
        let parentDir = currentDir.deletingLastPathComponent().lastPathComponent
        let grandparentDir = currentDir.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
        
        // 优先尝试使用上一级目录作为专辑名称（如果不是 CD 目录）
        if !parentDir.isEmpty && !parentDir.hasPrefix("CD ") {
            album = parentDir
        } else if !grandparentDir.isEmpty {
            // 如果上一级是 CD 目录，使用再上一级目录
            album = grandparentDir
        } else if !currentDirName.isEmpty {
            // 最后使用当前目录
            album = currentDirName
        }
    }
    
    /// 在当前目录及上级目录查找封面图片
    /// - Parameter url: 音乐文件的 URL
    /// - Returns: 找到的封面图片数据，失败则返回 nil
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
    
    /// 在当前目录及上级目录查找艺人图片
    /// - Parameters:
    ///   - url: 音乐文件的 URL
    ///   - artistName: 艺人名称
    /// - Returns: 找到的艺人图片数据，失败则返回 nil
    static func findArtistImage(from url: URL, artistName: String) -> Data? {
        let fileManager = FileManager.default
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp"]
        
        // 从当前文件所在目录开始，向上查找
        var currentDirectory = url.deletingLastPathComponent()
        
        // 最多向上查找 5 级目录
        for _ in 0..<5 {
            // 尝试在当前目录查找艺人图片
            for ext in imageExtensions {
                let artistImageURL = currentDirectory.appendingPathComponent("\(artistName).\(ext)")
                if fileManager.fileExists(atPath: artistImageURL.path) {
                    if let data = try? Data(contentsOf: artistImageURL) {
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
