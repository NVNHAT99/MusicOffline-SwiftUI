//
//  SettingViewState.swift
//  MusicApp
//
//  Created by Nhat on 9/25/23.
//

import Foundation

struct SettingViewState {
    var isTimerOn: Bool = false
    var ipAdress: String?
    var isServerOn: Bool = false
    var messageToastView: String = String.empty
    var isShowToastView: Bool = false
    var appVersion: String = ""
    var selectedLanguageDisplay: String = "English"
    var isShowDeleteConfirm: Bool = false
    var isShowShareSheet: Bool = false
}
