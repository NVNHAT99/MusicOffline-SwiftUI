//
//  WebServerWrapper.swift
//  MusicApp
//
//  Created by Nhat on 5/31/23.
//

import GCDWebServer
import Combine

enum WebLoaderResult {
    case startSuccess(ipAddress: String)
    case stopSucesss
    case startFailed
    case stopFailed
    case alreadyRuning
}

protocol WebServerGCDServiceProtocol {
    var loaderStateResultPublisher: AnyPublisher<WebLoaderResult, Never> { get }
    var uploadedFilePublisher: AnyPublisher<String, Never> { get }
    var removeFilePublisher: AnyPublisher<String, Never> { get }
    var updateFilePathPublisher: AnyPublisher<(String, String), Never> { get }
    func startWebUploader()
    func stopWebUploader()
}

final class WebServerGCDService: NSObject, WebServerGCDServiceProtocol {

    
    
    static let shared = WebServerGCDService()
    
    private var webUploader: GCDWebUploader?
    
    private let loaderStateResultSubject = PassthroughSubject<WebLoaderResult, Never>()
    private let uploadedFileSubject = PassthroughSubject<String, Never>()
    private let removeFileSubject = PassthroughSubject<String, Never>()
    private let updatePathSubject = PassthroughSubject<(String, String), Never>()
    
    var loaderStateResultPublisher: AnyPublisher<WebLoaderResult, Never> {
        loaderStateResultSubject.eraseToAnyPublisher()
    }
    
    var uploadedFilePublisher: AnyPublisher<String, Never> {
        uploadedFileSubject.eraseToAnyPublisher()
    }
    
    var removeFilePublisher: AnyPublisher<String, Never> {
        removeFileSubject.eraseToAnyPublisher()
    }
    
    var updateFilePathPublisher: AnyPublisher<(String, String), Never> {
        updatePathSubject.eraseToAnyPublisher()
    }
    
    private override init() {
        super.init()
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        webUploader = GCDWebUploader(uploadDirectory: documentsPath)
        webUploader?.delegate = self
    }
    
    func startWebUploader() {
        guard let webUploader = webUploader else {
            loaderStateResultSubject.send(.startFailed)
            return
        }
        
        if webUploader.isRunning {
            if let serverURL = webUploader.serverURL {
                let str = serverURL.absoluteString
                let start = str.index(str.startIndex, offsetBy: 7)
                let end = str.index(str.endIndex, offsetBy: -1)
                let ipAddressStr =  "Http://\(String(str[start..<end]))/"
                loaderStateResultSubject.send(.startSuccess(ipAddress: ipAddressStr))
            } else {
                loaderStateResultSubject.send(.startFailed)
            }
            return
        }

        let options: [String: Any] = [
            "Port": 61234,
            "AutomaticallySuspendInBackground": false
        ]
        
        do {
            try webUploader.start(options: options)
        } catch {
            print("Web server start error: \(error)")
            loaderStateResultSubject.send(.startFailed)
            return
        }
        
        webUploader.allowedFileExtensions = ["mp3", "m4a", "wav"]
        
        if let serverURL = webUploader.serverURL {
            let str = serverURL.absoluteString
            let start = str.index(str.startIndex, offsetBy: 7)
            let end = str.index(str.endIndex, offsetBy: -1)
            let ipAddressStr =  "\(String(str[start..<end]))"
            loaderStateResultSubject.send(.startSuccess(ipAddress: ipAddressStr))
        } else {
            loaderStateResultSubject.send(.startFailed)
        }
    }
    
    func stopWebUploader() {
        guard let webUploader = webUploader else {
            loaderStateResultSubject.send(.stopFailed)
            return
        }

        if webUploader.isRunning {
            webUploader.stop()
            loaderStateResultSubject.send(.stopSucesss)
        }
    }
}

extension WebServerGCDService: GCDWebUploaderDelegate {
    func webUploader(_ uploader: GCDWebUploader, didUploadFileAtPath path: String) {
        uploadedFileSubject.send(path)
    }
    
    func webUploader(_ uploader: GCDWebUploader, didDeleteItemAtPath path: String) {
        removeFileSubject.send(path)
    }
    
    func webUploader(_ uploader: GCDWebUploader, didMoveItemFromPath fromPath: String, toPath: String) {
        updatePathSubject.send((fromPath, toPath))
    }
}
