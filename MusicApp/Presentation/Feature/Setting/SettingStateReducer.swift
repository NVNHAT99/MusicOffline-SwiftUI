//
//  SettingStateReducer.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Protocol for Setting state reducer
protocol SettingStateReducerProtocol {
    func reduce(_ state: SettingViewState, with action: SettingStateAction) -> SettingViewState
}

/// Implementation of Setting state reducer
final class SettingStateReducerImpl: SettingStateReducerProtocol {
    func reduce(_ state: SettingViewState, with action: SettingStateAction) -> SettingViewState {
        var newState = state

        switch action {
        case .setServerOn(let isOn, let ipAddress):
            newState.isServerOn = isOn
            newState.ipAdress = ipAddress

        case .setShowToast(let show, let message):
            newState.isShowToastView = show
            newState.messageToastView = message

        case .setTimerOn(let isOn):
            newState.isTimerOn = isOn
        }

        return newState
    }
}
