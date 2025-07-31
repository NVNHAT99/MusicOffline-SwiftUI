//
//  Helper.swift
//  MusicApp
//
//  Created by Nhat on 5/31/23.
//

import Foundation
import SwiftUI

final class Helper {
    static let shared: Helper = Helper()
    
    private init() {}
    
    var safeAreaInsets: UIEdgeInsets? {
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            return scene?.windows.first?.safeAreaInsets
    }
    
    var keyWindown: UIWindow? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first
    }
}
