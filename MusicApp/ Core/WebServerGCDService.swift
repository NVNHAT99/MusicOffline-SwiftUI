//
//  WebServerWrapper.swift
//  MusicApp
//
//  Created by Nhat on 5/31/23.
//

import GCDWebServer
import Foundation
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
        Logger.info("WebServerGCDService initialized with documents path: \(documentsPath)")
    }
    
    func startWebUploader() {
        Logger.debug("WebServerGCDService.startWebUploader() called")

        guard let webUploader = webUploader else {
            Logger.error("Web uploader is not initialized")
            loaderStateResultSubject.send(.startFailed)
            return
        }

        if webUploader.isRunning {
            Logger.info("Web server is already running")
            if let serverURL = webUploader.serverURL {
                let str = serverURL.absoluteString
                let start = str.index(str.startIndex, offsetBy: 7)
                let end = str.index(str.endIndex, offsetBy: -1)
                let ipAddressStr =  "Http://\(String(str[start..<end]))/"
                Logger.info("Web server already running at: \(ipAddressStr)")
                loaderStateResultSubject.send(.startSuccess(ipAddress: ipAddressStr))
            } else {
                Logger.error("Web server is running but no server URL available")
                loaderStateResultSubject.send(.startFailed)
            }
            return
        }

        Logger.info("Starting web server on port 61234")
        let options: [String: Any] = [
            "Port": 61234,
            "AutomaticallySuspendInBackground": false
        ]

        do {
            try webUploader.start(options: options)
            Logger.info("Web server started successfully")
        } catch {
            Logger.error("Failed to start web server: \(error)")
            print("Web server start error: \(error)")
            loaderStateResultSubject.send(.startFailed)
            return
        }

        webUploader.allowedFileExtensions = ["mp3", "m4a", "wav"]
        Logger.debug("Set allowed file extensions: mp3, m4a, wav")

        if let serverURL = webUploader.serverURL {
            let str = serverURL.absoluteString
            let start = str.index(str.startIndex, offsetBy: 7)
            let end = str.index(str.endIndex, offsetBy: -1)
            let ipAddressStr =  "\(String(str[start..<end]))"
            Logger.info("Web server available at: \(ipAddressStr)")
            loaderStateResultSubject.send(.startSuccess(ipAddress: ipAddressStr))
        } else {
            Logger.error("Web server started but no server URL available")
            loaderStateResultSubject.send(.startFailed)
        }
    }
    
    func stopWebUploader() {
        Logger.debug("WebServerGCDService.stopWebUploader() called")

        guard let webUploader = webUploader else {
            Logger.error("Web uploader is not initialized")
            loaderStateResultSubject.send(.stopFailed)
            return
        }

        if webUploader.isRunning {
            Logger.info("Stopping web server")
            webUploader.stop()
            Logger.info("Web server stopped successfully")
            loaderStateResultSubject.send(.stopSucesss)
        } else {
            Logger.info("Web server is not running")
            loaderStateResultSubject.send(.stopSucesss)
        }
    }
}

extension WebServerGCDService: GCDWebUploaderDelegate {
    func webUploader(_ uploader: GCDWebUploader, didUploadFileAtPath path: String) {
        Logger.info("File uploaded at path: \(path)")
        uploadedFileSubject.send(path)
    }

    func webUploader(_ uploader: GCDWebUploader, didDeleteItemAtPath path: String) {
        Logger.info("File deleted at path: \(path)")
        removeFileSubject.send(path)
    }

    func webUploader(_ uploader: GCDWebUploader, didMoveItemFromPath fromPath: String, toPath: String) {
        Logger.info("File moved from \(fromPath) to \(toPath)")
        updatePathSubject.send((fromPath, toPath))
    }
}
