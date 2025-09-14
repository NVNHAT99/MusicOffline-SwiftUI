//
//  ImageCacheManager.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/9/25.
//

import Foundation
import CryptoKit

protocol ImageCacheProtocol {
    func get(for urlString: String) async -> Data?
    func set(_ imageData: Data, for urlString: String) async
}

actor ImageCacheManager: ImageCacheProtocol {
    
    private var memoryCache = NSCache<NSString, NSData>()
    private let diskURL: URL
    static let shared = ImageCacheManager()

    private init() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskURL = cacheDir.appendingPathComponent("ImageCache")
        try? FileManager.default.createDirectory(at: diskURL, withIntermediateDirectories: true)
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // max cache in ram is 50MB
    }
    
    private func key(for urlString: String) -> String {
        let hash = SHA256.hash(data: Data(urlString.utf8))
        return hash.map({String(format:"%02x", $0)}).joined()
    }
    
    // async function for actor auto handle thread safety
    func get(for urlString: String) async -> Data? {
        
        let key = key(for: urlString)
        if let imageData = memoryCache.object(forKey: key as NSString) { return imageData as Data }
        let path = diskURL.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: path) else { return nil }
        memoryCache.setObject(data as NSData, forKey: key as NSString)
        return data
    }
    
    func set(_ imageData: Data, for urlString: String) async {
        let key = key(for: urlString)
        memoryCache.setObject(imageData as NSData, forKey: key as NSString)
        // disk cache
        try? imageData.write(to: diskURL.appendingPathComponent(key))
    }
}
