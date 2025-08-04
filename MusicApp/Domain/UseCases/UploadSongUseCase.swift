//
//  UploadSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/31/25.
//

import Combine

protocol UploadSongUseCaseProtocol {
    var uploadedFilePublisher: AnyPublisher<String, Never> { get }
    var deletedFilePublisher: AnyPublisher<String, Never> { get }
    var updatePathFilePublisher: AnyPublisher<(String, String), Never> { get }
}

final class UploadSongUseCase: UploadSongUseCaseProtocol {
    
    var uploadedFilePublisher: AnyPublisher<String, Never> {
        service.uploadedFilePublisher
    }
    
    var deletedFilePublisher: AnyPublisher<String, Never> {
        service.removeFilePublisher
    }
    
    var updatePathFilePublisher: AnyPublisher<(String, String), Never> {
        service.updateFilePathPublisher
    }
    
    private let service: WebServerGCDServiceProtocol
    
    init(service: WebServerGCDServiceProtocol = WebServerGCDService.shared) {
        self.service = service
    }
    
}
