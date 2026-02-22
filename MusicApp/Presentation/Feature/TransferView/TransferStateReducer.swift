//
//  TransferStateReducer.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Protocol for Transfer state reducer
protocol TransferStateReducerProtocol {
    func reduce(_ state: TransferViewState, with action: TransferStateAction) -> TransferViewState
}

/// Implementation of Transfer state reducer (pure function)
final class TransferStateReducerImpl: TransferStateReducerProtocol {

    func reduce(_ state: TransferViewState, with action: TransferStateAction) -> TransferViewState {
        var newState = state

        switch action {
        case .setServerOn(let isOn, let ipAddress):
            newState.isServerOn = isOn
            newState.ipAdress = ipAddress

        case .setShowToast(let show, let message):
            newState.isShowToastView = show
            newState.messageToastView = message

        case .setShowLoading(let loading):
            newState.showLoading = loading

        case .setShowForceSaveDialog(let show):
            newState.isShowForceSaveDialog = show
        }

        return newState
    }
}
