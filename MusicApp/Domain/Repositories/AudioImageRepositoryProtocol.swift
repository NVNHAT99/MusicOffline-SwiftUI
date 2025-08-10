//
//  AudioImageRepositoryProtocol.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/9/25.
//

import Foundation

public protocol AudioImageRepositoryProtocol {
    func getImageData(for audioURLString: String) async -> Data?
    func setImageData(_ data: Data, for audioURLString: String) async
    func hasArtwork(for audioURLString: String) async -> Bool
}
