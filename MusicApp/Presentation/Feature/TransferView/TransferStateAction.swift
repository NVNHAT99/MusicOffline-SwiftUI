//
//  TransferStateAction.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Actions that can transform the Transfer state
enum TransferStateAction {
    case setServerOn(Bool, ipAddress: String?)
    case setShowToast(Bool, message: String)
    case setShowLoading(Bool)
    case setShowForceSaveDialog(Bool)
}
