//
//  MusicAppApp.swift
//  MusicApp
//
//  Created by Nhat on 5/7/23.
//

import SwiftUI
import UIKit
@main
struct MusicAppApp: App {
    @Environment(\.scenePhase) var scenePhase
    @State var appState: AppState = AppState()
    init() {
        PlaylistManager.provide(PlayViewModel())
        PlaylistManager.shared.setUpSubscrib()
    }
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewViewModel())
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            default:
                break
            }
        }
    }
}


// MARK: - TODO: tao man hinh mini notification
// tao constant cho may cai string
// tao icon cho app
// tao mot cai toask view cho viec hien thi nhu add playlist thanh cong, xoa bai hat thanh cong, hen gio thanh cong, playlist empty check lai
// lam man hinh setting
