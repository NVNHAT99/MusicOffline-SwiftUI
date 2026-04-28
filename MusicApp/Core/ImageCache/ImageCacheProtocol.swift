import Foundation
import UIKit

// MARK: - ImageCacheProtocol
protocol ImageCacheProtocol: AnyObject {
    func get(for urlString: String) async -> Data?
    func set(_ imageData: Data, for urlString: String)
    func remove(for urlString: String)
    func clearAll()
    func clearMemory()
    func clearDisk()
    func getCacheSize() -> (memory: Int, disk: Int)
}

// MARK: - ImageCacheManagerDelegate
protocol ImageCacheManagerDelegate: AnyObject {
    func cacheDidReceiveMemoryWarning()
    func cacheDidReceiveMemoryWarning(_ cache: ImageCacheProtocol)
}

// MARK: - ImageCacheConfiguration
struct ImageCacheConfiguration {
    let memoryCountLimit: Int
    let memoryTotalCostLimit: Int
    let diskStorageLimit: Int
    let cacheExpiryDays: Int
    let enableDiskCache: Bool

    static let `default` = ImageCacheConfiguration(
        memoryCountLimit: 150,
        memoryTotalCostLimit: 100 * 1024 * 1024,
        diskStorageLimit: 500 * 1024 * 1024,
        cacheExpiryDays: 30,
        enableDiskCache: true
    )

    static let lightweight = ImageCacheConfiguration(
        memoryCountLimit: 50,
        memoryTotalCostLimit: 25 * 1024 * 1024,
        diskStorageLimit: 100 * 1024 * 1024,
        cacheExpiryDays: 7,
        enableDiskCache: true
    )
}
