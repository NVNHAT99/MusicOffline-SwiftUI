//
//  ManageWebUploaderUseCaseProtocol.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/30/25.
//

import Combine

protocol ManageWebUploaderUseCaseProtocol {
    func start()
    func stop()
    var statePublisher: AnyPublisher<WebLoaderResult, Never> { get }
}

final class ManageWebUploaderUseCase: ManageWebUploaderUseCaseProtocol {
    
    var statePublisher: AnyPublisher<WebLoaderResult, Never> {
        service.loaderStateResultPublisher
    }
    
    private let service: WebServerGCDServiceProtocol
    
    init(service: WebServerGCDServiceProtocol = WebServerGCDService.shared) {
        self.service = service
    }
    
    func start() {
        service.startWebUploader()
    }
    
    func stop() {
        service.stopWebUploader()
    }
    
}
