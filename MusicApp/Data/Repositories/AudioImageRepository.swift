//
//  AudioImageRepository.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/9/25.
//

import Foundation

/// Repository Implementation sử dụng Cache
final class  AudioImageRepositoryImpl: AudioImageRepositoryProtocol {
    
    private let cache: ImageCacheProtocol

    init(cache: ImageCacheProtocol = ImageCacheFactory.shared) {
        self.cache = cache
    }

    
    func getImageData(for audioURLString: String) async -> Data? {
        if let imageData = await cache.get(for: audioURLString) {
            return imageData
        }
        return nil
    }
    
    func setImageData(_ data: Data, for audioURLString: String) {
        cache.set(data, for: audioURLString)
    }
    
    func hasArtwork(for audioURLString: String) async -> Bool {
        return await cache.get(for: audioURLString) != nil
    }
}
