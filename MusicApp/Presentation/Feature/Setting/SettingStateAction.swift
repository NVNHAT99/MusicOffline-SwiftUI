//
//  SettingStateAction.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// State actions for Setting feature
enum SettingStateAction {
    case setServerOn(Bool, ipAddress: String?)
    case setShowToast(Bool, message: String)
    case setTimerOn(Bool)
    case setShowDeleteConfirm(Bool)
    case setShowShareSheet(Bool)
    case setLanguageDisplay(String)
}
