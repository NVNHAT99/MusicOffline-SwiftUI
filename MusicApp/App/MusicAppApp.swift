//
//  MusicAppApp.swift
//  MusicApp
//
//  Created by Nhat on 5/7/23.
//

import SwiftUI

@main
struct MusicAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewVM())
        }
    }
}
