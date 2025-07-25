//
//  AppState.swift
//  MusicApp
//
//  Created by Nhat on 9/13/23.
//

import Foundation
import UIKit

class AppState: ObservableObject {

    private var observers = [NSObjectProtocol]()

    init() {
        observers.append(
            NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main, using: { _ in
                PlaylistManager.shared.saveLastdataUser()
                WebServerWrapper.shared.stopWebUploader()
            })
        )
    }
    
    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }
}
