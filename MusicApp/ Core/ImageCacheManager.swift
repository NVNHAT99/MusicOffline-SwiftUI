//
//  ImageCacheManager.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/9/25.
//

import Foundation
import CryptoKit
import Combine
import UIKit
import AVFoundation

// MARK: - Protocols
protocol ImageCacheProtocol: AnyObject {
    func get(for urlString: String) async -> Data?
    func set(_ imageData: Data, for urlString: String) async
    func remove(for urlString: String) async
    func clearAll() async
    func clearMemory() async
    func clearDisk() async
    func getCacheSize() async -> (memory: Int, disk: Int)
}

protocol ImageCacheManagerDelegate: AnyObject {
    func cacheDidReceiveMemoryWarning()
    func cacheDidReceiveMemoryWarning(_ cache: ImageCacheProtocol)
}

// MARK: - Cache Configuration
struct ImageCacheConfiguration {
    let memoryCountLimit: Int
    let memoryTotalCostLimit: Int
    let diskStorageLimit: Int
    let cacheExpiryDays: Int
    let enableDiskCache: Bool

    static let `default` = ImageCacheConfiguration(
        memoryCountLimit: 150,
        memoryTotalCostLimit: 100 * 1024 * 1024, // 100MB
        diskStorageLimit: 500 * 1024 * 1024,     // 500MB
        cacheExpiryDays: 30,
        enableDiskCache: true
    )

    static let lightweight = ImageCacheConfiguration(
        memoryCountLimit: 50,
        memoryTotalCostLimit: 25 * 1024 * 1024,  // 25MB
        diskStorageLimit: 100 * 1024 * 1024,     // 100MB
        cacheExpiryDays: 7,
        enableDiskCache: true
    )
}

// MARK: - Image Cache Manager
final class ImageCacheManager: NSObject, ImageCacheProtocol {

    // MARK: - Properties
    private let memoryCache = NSCache<NSString, NSData>()
    private let diskURL: URL
    private let configuration: ImageCacheConfiguration
    private let fileManager = FileManager.default
    private let accessQueue = DispatchQueue(label: "com.musicapp.imagecache.access", qos: .utility)
    private var accessOrder = NSMutableOrderedSet()

    // MARK: - Initialization
    init(configuration: ImageCacheConfiguration = .default) {
        self.configuration = configuration

        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.diskURL = cacheDir.appendingPathComponent("ImageCache")

        super.init()

        // Initialize basic cache properties synchronously
        setupMemoryCacheSync()
        observeMemoryWarningsSync()

        // Setup disk cache asynchronously
        Task {
            await setupCacheAsync()
        }
    }

    // MARK: - Setup
    private func setupCache() {
        guard configuration.enableDiskCache else { return }

        try? fileManager.createDirectory(at: diskURL, withIntermediateDirectories: true)
        Task {
            await cleanupExpiredCacheAsync()
        }
    }

    private func setupMemoryCache() {
        memoryCache.countLimit = configuration.memoryCountLimit
        memoryCache.totalCostLimit = configuration.memoryTotalCostLimit
        memoryCache.delegate = self
    }

    private func observeMemoryWarnings() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleMemoryWarning()
            }
        }
    }

    // MARK: - Synchronous Setup (called from init)
    private func setupMemoryCacheSync() {
        memoryCache.countLimit = configuration.memoryCountLimit
        memoryCache.totalCostLimit = configuration.memoryTotalCostLimit
        memoryCache.delegate = self
    }

    private func observeMemoryWarningsSync() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleMemoryWarning()
            }
        }
    }

    // MARK: - Asynchronous Setup (called from init)
    private func setupCacheAsync() async {
        guard configuration.enableDiskCache else { return }

        try? fileManager.createDirectory(at: diskURL, withIntermediateDirectories: true)
        await cleanupExpiredCacheAsync()
    }

    // MARK: - Cache Operations
    func get(for urlString: String) async -> Data? {
        let key = generateKey(for: urlString)

        // Try memory cache first
        if let cachedData = memoryCache.object(forKey: key as NSString) {
            accessQueue.async {
                self.updateAccessOrder(key)
            }
            return cachedData as Data
        }

        // Try disk cache
        guard configuration.enableDiskCache else {
            // Cache doesn't exist, try to extract image from audio file
            return await extractImageFromAudioFile(urlString)
        }

        let fileURL = diskURL.appendingPathComponent(key)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            // Cache doesn't exist, try to extract image from audio file
            if let audioImageData = await extractImageFromAudioFile(urlString) {
                // Cache the extracted image
                await set(audioImageData, for: urlString)
                return audioImageData
            } else {
                return nil
            }
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)

            // Check if cache is expired
            if let creationDate = attributes[.creationDate] as? Date,
               creationDate.addingTimeInterval(TimeInterval(configuration.cacheExpiryDays * 24 * 60 * 60)) < Date() {
                try? fileManager.removeItem(at: fileURL)
                // Cache doesn't exist, try to extract image from audio file
                return await extractImageFromAudioFile(urlString)
            }

            // Cache in memory
            accessQueue.async {
                self.memoryCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
                self.updateAccessOrder(key)
            }

            return data
        } catch {
            // Remove corrupted file
            try? fileManager.removeItem(at: fileURL)
            // Cache doesn't exist, try to extract image from audio file
            return await extractImageFromAudioFile(urlString)
        }
    }

    func set(_ imageData: Data, for urlString: String) async {
        guard !imageData.isEmpty else { return }

        let key = generateKey(for: urlString)
        let cost = imageData.count

        // Cache in memory
        memoryCache.setObject(imageData as NSData, forKey: key as NSString, cost: cost)
        updateAccessOrder(key)

        // Cache on disk
        guard configuration.enableDiskCache else { return }

        let fileURL = diskURL.appendingPathComponent(key)

        do {
            // Check disk space
            if let currentSize = await getCurrentDiskSize(),
               currentSize + cost > configuration.diskStorageLimit {
                await cleanupOldestFiles(requiredSpace: cost)
            }

            try imageData.write(to: fileURL)
        } catch {
            print("⚠️ Failed to cache image on disk: \(error)")
        }
    }

    func remove(for urlString: String) async {
        let key = generateKey(for: urlString)

        // Remove from memory
        memoryCache.removeObject(forKey: key as NSString)
        accessOrder.remove(key)

        // Remove from disk
        guard configuration.enableDiskCache else { return }

        let fileURL = diskURL.appendingPathComponent(key)
        try? fileManager.removeItem(at: fileURL)
    }

    func clearAll() async {
        await clearMemory()
        await clearDisk()
    }

    func clearMemory() async {
        memoryCache.removeAllObjects()
        accessOrder.removeAllObjects()
    }

    func clearDisk() async {
        guard configuration.enableDiskCache else { return }

        try? fileManager.removeItem(at: diskURL)
        try? fileManager.createDirectory(at: diskURL, withIntermediateDirectories: true)
    }

    func getCacheSize() async -> (memory: Int, disk: Int) {
        let memorySize = getCurrentMemorySize()
        let diskSize = await getCurrentDiskSize() ?? 0

        return (memorySize, diskSize)
    }

    // MARK: - Private Helpers
    private func generateKey(for urlString: String) -> String {
        let normalizedURL = urlString
            .components(separatedBy: "?")[0] // Remove query parameters
            .lowercased()

        let hash = SHA256.hash(data: Data(normalizedURL.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private func updateAccessOrder(_ key: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.accessOrder.remove(key)
            self.accessOrder.add(key)

            // Evict if over limit
            while self.accessOrder.count > self.configuration.memoryCountLimit {
                if let oldestKey = self.accessOrder.firstObject as? String {
                    self.memoryCache.removeObject(forKey: oldestKey as NSString)
                    self.accessOrder.remove(oldestKey)
                }
            }
        }
    }

    private func getCurrentMemorySize() -> Int {
        // Estimate current memory usage
        return accessOrder.count * 1024 // Approximate average image size
    }

    private func getCurrentDiskSize() async -> Int? {
        guard configuration.enableDiskCache else { return 0 }

        guard fileManager.fileExists(atPath: diskURL.path) else { return 0 }

        do {
            let resources = try fileManager.contentsOfDirectory(
                at: diskURL,
                includingPropertiesForKeys: [.fileSizeKey]
            )

            return try resources.reduce(0) { total, url in
                let resources = try url.resourceValues(forKeys: [.fileSizeKey])
                return total + (resources.fileSize ?? 0)
            }
        } catch {
            return 0
        }
    }

    private func cleanupExpiredCache() {
        guard configuration.enableDiskCache else { return }

        do {
            let resources = try fileManager.contentsOfDirectory(
                at: diskURL,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]
            )

            let expiryDate = Date().addingTimeInterval(-TimeInterval(configuration.cacheExpiryDays * 24 * 60 * 60))

            for url in resources {
                guard let creationDate = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate,
                      creationDate < expiryDate else { continue }

                try? fileManager.removeItem(at: url)
            }
        } catch {
            print("⚠️ Failed to cleanup expired cache: \(error)")
        }
    }

    private func cleanupExpiredCacheAsync() async {
        guard configuration.enableDiskCache else { return }

        do {
            let resources = try fileManager.contentsOfDirectory(
                at: diskURL,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]
            )

            let expiryDate = Date().addingTimeInterval(-TimeInterval(configuration.cacheExpiryDays * 24 * 60 * 60))

            for url in resources {
                guard let creationDate = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate,
                      creationDate < expiryDate else { continue }

                try? fileManager.removeItem(at: url)
            }
        } catch {
            print("⚠️ Failed to cleanup expired cache: \(error)")
        }
    }

    private func cleanupOldestFiles(requiredSpace: Int) async {
        do {
            let resources = try fileManager.contentsOfDirectory(
                at: diskURL,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]
            )

            // Sort by creation date (oldest first)
            let sortedResources = try resources.sorted {
                let date1 = try $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1 < date2
            }

            var freedSpace = 0
            for url in sortedResources {
                guard let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else { continue }

                try? fileManager.removeItem(at: url)
                freedSpace += fileSize

                if freedSpace >= requiredSpace { break }
            }
        } catch {
            print("⚠️ Failed to cleanup old files: \(error)")
        }
    }

    private func handleMemoryWarning() {
        print("🗑️ Memory warning received, clearing memory cache")
        Task {
            await clearMemory()
        }

        // Optionally notify delegates
        // delegates.forEach { $0.cacheDidReceiveMemoryWarning(self) }
    }

    // MARK: - Audio File Image Extraction
    private func extractImageFromAudioFile(_ urlString: String) async -> Data? {
        let audioURL = URL(fileURLWithPath: urlString)

        do {
            let audioAsset = AVURLAsset(url: audioURL)
            let artworkData = try await extractArtwork(from: audioAsset)
            return artworkData
        } catch {
            print("⚠️ Failed to extract artwork from audio file: \(error)")
            return nil
        }
    }

    private func extractArtwork(from asset: AVURLAsset) async throws -> Data? {
        let arrayMetaData = try await asset.load(.metadata)
        for metaData in arrayMetaData {
            if let commonKey = metaData.commonKey?.rawValue, let value = try await metaData.load(.value) {
                switch commonKey {
                case AVMetadataKey.commonKeyArtwork.rawValue:
                    if let data = value as? Data {
                        return data
                    }
                default:
                    break
                }
            }
        }
        return nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - NSCacheDelegate
extension ImageCacheManager: NSCacheDelegate {
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        // Handle eviction if needed
        if let key = accessOrder.firstObject as? String {
            accessOrder.remove(key)
        }
    }
}

// MARK: - Cache Factory
enum ImageCacheFactory {
    static func createDefaultCache() -> ImageCacheManager {
        return ImageCacheManager(configuration: .default)
    }

    static func createLightweightCache() -> ImageCacheManager {
        return ImageCacheManager(configuration: .lightweight)
    }

    static func createCustomCache(
        memoryCountLimit: Int = 150,
        memoryTotalCostLimit: Int = 100 * 1024 * 1024,
        diskStorageLimit: Int = 500 * 1024 * 1024,
        cacheExpiryDays: Int = 30,
        enableDiskCache: Bool = true
    ) -> ImageCacheManager {
        let config = ImageCacheConfiguration(
            memoryCountLimit: memoryCountLimit,
            memoryTotalCostLimit: memoryTotalCostLimit,
            diskStorageLimit: diskStorageLimit,
            cacheExpiryDays: cacheExpiryDays,
            enableDiskCache: enableDiskCache
        )
        return ImageCacheManager(configuration: config)
    }
}
