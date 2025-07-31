//
//  UploadSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/31/25.
//

import Combine

protocol UploadSongUseCaseProtocol {
    var uploadedFilePublisher: AnyPublisher<String, Never> { get }
}

final class UploadSongUseCase: UploadSongUseCaseProtocol {
    
    var uploadedFilePublisher: AnyPublisher<String, Never> {
        service.uploadedFilePublisher
    }
    
    private let service: WebServerGCDServiceProtocol
    
    init(service: WebServerGCDServiceProtocol = WebServerGCDService.shared) {
        self.service = service
    }
    
}
