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

// Protocols + config extracted to ImageCacheProtocol.swift
// Factory extracted to ImageCacheFactory.swift

// MARK: - Image Cache Manager
final class ImageCacheManager: NSObject, ImageCacheProtocol {

    // MARK: - Properties
    private let memoryCache = NSCache<NSString, NSData>()
    private let diskURL: URL
    private let configuration: ImageCacheConfiguration
    private let fileManager = FileManager.default
    private let accessQueue = DispatchQueue(label: "com.musicapp.imagecache.access", qos: .utility)
    private var accessOrder = NSMutableOrderedSet()
    private var memoryWarningObserver: NSObjectProtocol?

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

    // MARK: - Synchronous Setup (called from init)
    private func setupMemoryCacheSync() {
        memoryCache.countLimit = configuration.memoryCountLimit
        memoryCache.totalCostLimit = configuration.memoryTotalCostLimit
        memoryCache.delegate = self
    }

    private func observeMemoryWarningsSync() {
        // Retain the token: block-based observers are NOT removed by
        // removeObserver(self) — only the token API can unregister them.
        memoryWarningObserver = NotificationCenter.default.addObserver(
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
            updateAccessOrder(key)
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
                set(audioImageData, for: urlString)
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
            memoryCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
            updateAccessOrder(key)

            return data
        } catch {
            // Remove corrupted file
            try? fileManager.removeItem(at: fileURL)
            // Cache doesn't exist, try to extract image from audio file
            return await extractImageFromAudioFile(urlString)
        }
    }

    func set(_ imageData: Data, for urlString: String) {
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
            if let currentSize = getCurrentDiskSize(),
               currentSize + cost > configuration.diskStorageLimit {
                cleanupOldestFilesSync(requiredSpace: cost)
            }

            try imageData.write(to: fileURL)
        } catch {
            print("⚠️ Failed to cache image on disk: \(error)")
        }
    }

    func remove(for urlString: String) {
        let key = generateKey(for: urlString)

        // Remove from memory
        memoryCache.removeObject(forKey: key as NSString)
        accessOrder.remove(key)

        // Remove from disk
        guard configuration.enableDiskCache else { return }

        let fileURL = diskURL.appendingPathComponent(key)
        try? fileManager.removeItem(at: fileURL)
    }

    func clearAll() {
        clearMemory()
        clearDisk()
    }

    func clearMemory() {
        memoryCache.removeAllObjects()
        accessOrder.removeAllObjects()
    }

    func clearDisk() {
        guard configuration.enableDiskCache else { return }

        try? fileManager.removeItem(at: diskURL)
        try? fileManager.createDirectory(at: diskURL, withIntermediateDirectories: true)
    }

    func getCacheSize() -> (memory: Int, disk: Int) {
        let memorySize = getCurrentMemorySize()
        let diskSize = getCurrentDiskSize() ?? 0

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

    private func getCurrentDiskSize() -> Int? {
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

    private func cleanupOldestFilesSync(requiredSpace: Int) {
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
        clearMemory()

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
        let metadata = try await asset.load(.metadata)
        guard let item = metadata.first(where: { $0.commonKey?.rawValue == AVMetadataKey.commonKeyArtwork.rawValue }),
              let data = try await item.load(.dataValue) else {
            return nil
        }
        return data
    }

    deinit {
        if let memoryWarningObserver {
            NotificationCenter.default.removeObserver(memoryWarningObserver)
        }
    }
}

// MARK: - NSCacheDelegate
extension ImageCacheManager: NSCacheDelegate {
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        if let key = accessOrder.firstObject as? String {
            accessOrder.remove(key)
        }
    }
}
// Factory extracted to ImageCacheFactory.swift
