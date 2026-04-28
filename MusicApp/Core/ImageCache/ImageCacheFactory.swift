import Foundation

// MARK: - ImageCacheFactory
enum ImageCacheFactory {
    static func createDefaultCache() -> ImageCacheManager {
        ImageCacheManager(configuration: .default)
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
