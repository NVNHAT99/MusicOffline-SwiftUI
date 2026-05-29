import Foundation

// MARK: - ImageCacheFactory
enum ImageCacheFactory {
    /// Single process-wide cache. Multiple instances each register their own
    /// memory-warning observer and fragment the in-memory/disk cache, so every
    /// caller must share this one. DI passes this same instance around.
    static let shared = ImageCacheManager(configuration: .default)

    static func createDefaultCache() -> ImageCacheManager {
        shared
    }

    static func createLightweightCache() -> ImageCacheManager {
        ImageCacheManager(configuration: .lightweight)
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
