//
//  WebServerWrapper.swift
//  MusicApp
//
//  Created by Nhat on 5/31/23.
//

import Foundation
import GCDWebServer

class WebServerWrapper {
    private let webServer: GCDWebServer
    
    init() {
        webServer = GCDWebServer()
    }
    
    func start() {
        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { request in
            let response = GCDWebServerDataResponse(html:"<html><body><p>Hello, World!</p></body></html>")
            return response
        }
        
        webServer.start(withPort: 8080, bonjourName: "GCD Web Server")
    }
    
    func stop() {
        webServer.stop()
        print("Server stopped")
    }
}
